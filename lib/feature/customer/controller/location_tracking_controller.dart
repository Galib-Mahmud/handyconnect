import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../../../core/endpoint/api_client.dart';
import '../../../core/endpoint/api_endpoint.dart';
import '../../../core/local_storage/user_info.dart';

/// Connection state surfaced to the UI so it can show a subtle
/// "connecting…" / "live" / "location may be outdated" indicator.
enum TrackingConnectionState {
  connecting,
  live,
  fallbackPolling,
  stopped,
  error,
}

/// Owns everything related to the job pin + live provider pin for a
/// single request: initial REST load, WebSocket subscription,
/// exponential-backoff reconnect, and REST polling fallback.
///
/// Deliberately separate from [InProgressController] — it only reads
/// `requestId`, never touches timeline/review/hire logic, and can be
/// disposed independently when the map leaves the widget tree.
class LocationTrackingController extends GetxController {
  LocationTrackingController({required this.requestId});

  final int requestId;
  final ApiClient _api = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── Job pin (fixed) ──────────────────────────────────────────
  final Rxn<double> jobLat = Rxn<double>();
  final Rxn<double> jobLng = Rxn<double>();
  final RxString jobAddress = ''.obs;

  // ── Provider pin (live) ──────────────────────────────────────
  final Rxn<double> providerLat = Rxn<double>();
  final Rxn<double> providerLng = Rxn<double>();
  final Rxn<DateTime> providerUpdatedAt = Rxn<DateTime>();

  final RxString jobStatus = ''.obs; // ACCEPTED / ON_THE_WAY / IN_PROGRESS…
  final Rx<TrackingConnectionState> connectionState =
      TrackingConnectionState.connecting.obs;

  static const _trackableStatuses = {'ACCEPTED', 'ON_THE_WAY'};
  static const _staleAfter = Duration(seconds: 45);
  static const _pollInterval = Duration(seconds: 12);
  static const _backoffSeconds = [1, 2, 4, 8, 16, 30];

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _disposed = false;

  bool get isTrackable => _trackableStatuses.contains(jobStatus.value);

  bool get hasProviderFix =>
      providerLat.value != null && providerLng.value != null;

  bool get isProviderStale {
    final t = providerUpdatedAt.value;
    if (t == null) return false;
    return DateTime.now().difference(t) > _staleAfter;
  }

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  @override
  void onClose() {
    _disposed = true;
    _teardown();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    await _loadInitial();
    if (isTrackable) {
      _connectWebSocket();
    } else {
      connectionState.value = TrackingConnectionState.stopped;
    }
  }

  // ── REST: initial load / fallback refresh ─────────────────────
  Future<void> _loadInitial() async {
    try {
      final res = await _api.get(
        '${ApiEndpoint.requests}$requestId/',
        requiresAuth: true,
      ) as Map<String, dynamic>;

      _applyJobPayload(res);
    } catch (e) {
      print('❌ [TRACKING] initial load error: $e');
      if (jobLat.value == null) {
        connectionState.value = TrackingConnectionState.error;
      }
    }
  }

  void _applyJobPayload(Map<String, dynamic> res) {
    jobStatus.value = (res['status'] as String?) ?? jobStatus.value;
    jobLat.value = (res['lat'] as num?)?.toDouble() ?? jobLat.value;
    jobLng.value = (res['lng'] as num?)?.toDouble() ?? jobLng.value;
    jobAddress.value = (res['address'] as String?) ?? jobAddress.value;

    final liveLat = (res['provider_live_lat'] as num?)?.toDouble();
    final liveLng = (res['provider_live_lng'] as num?)?.toDouble();
    if (liveLat != null && liveLng != null) {
      providerLat.value = liveLat;
      providerLng.value = liveLng;
      final ts = res['provider_live_updated_at'] as String?;
      if (ts != null) providerUpdatedAt.value = DateTime.tryParse(ts);
    }

    if (!isTrackable) {
      _teardown();
      connectionState.value = TrackingConnectionState.stopped;
    }
  }

  /// Call this from the screen/other controller when the job status
  /// changes (e.g. your existing 15s status poller) so tracking stops
  /// the instant the job leaves ACCEPTED / ON_THE_WAY, without waiting
  /// on this controller's own timers.
  void onStatusChanged(String newStatus) {
    jobStatus.value = newStatus;
    if (!isTrackable) {
      _teardown();
      connectionState.value = TrackingConnectionState.stopped;
    } else if (_channel == null && _pollTimer == null && !_disposed) {
      _connectWebSocket();
    }
  }

  // ── WebSocket ──────────────────────────────────────────────────
  void _connectWebSocket() {
    if (_disposed || !isTrackable) return;

    final token = UserInfo.getAccessTokenSync() ?? '';
    if (token.isEmpty) {
      print('❌ [TRACKING] no access token available, using REST fallback');
      _startPollingFallback();
      return;
    }

    connectionState.value = TrackingConnectionState.connecting;

    // Derived from your existing ApiEndpoint.baseUrl — no new constant
    // needed. https:// → wss://, http:// → ws://, same host/port.
    final uri = Uri.parse(
      '${_wsBaseUrl(ApiEndpoint.baseUrl)}/ws/tracking/$requestId/?token=$token',
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      _wsSub = _channel!.stream.listen(
        _onWsMessage,
        onDone: _onWsClosed,
        onError: _onWsError,
        cancelOnError: true,
      );
      connectionState.value = TrackingConnectionState.live;
      _reconnectAttempt = 0;
      _stopPollingFallback();
    } catch (e) {
      print('❌ [TRACKING] WS connect threw: $e');
      _scheduleReconnectOrFallback();
    }
  }

  void _onWsMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      switch (data['type'] as String?) {
        case 'snapshot':
          final job = data['job'] as Map<String, dynamic>?;
          if (job != null) {
            jobLat.value = (job['lat'] as num?)?.toDouble() ?? jobLat.value;
            jobLng.value = (job['lng'] as num?)?.toDouble() ?? jobLng.value;
            jobAddress.value =
                (job['address'] as String?) ?? jobAddress.value;
          }
          final live = data['provider_live'] as Map<String, dynamic>?;
          if (live != null) {
            providerLat.value = (live['lat'] as num?)?.toDouble();
            providerLng.value = (live['lng'] as num?)?.toDouble();
            final ts = live['updated_at'] as String?;
            if (ts != null) providerUpdatedAt.value = DateTime.tryParse(ts);
          }
          break;

        case 'provider_location':
          providerLat.value = (data['lat'] as num?)?.toDouble();
          providerLng.value = (data['lng'] as num?)?.toDouble();
          final ts = data['updated_at'] as String?;
          if (ts != null) providerUpdatedAt.value = DateTime.tryParse(ts);
          break;
      }
    } catch (e) {
      print('❌ [TRACKING] WS message parse error: $e');
    }
  }

  void _onWsClosed() {
    print('ℹ️ [TRACKING] WS closed');
    if (_disposed) return;
    if (isTrackable) {
      _scheduleReconnectOrFallback();
    } else {
      connectionState.value = TrackingConnectionState.stopped;
    }
  }

  void _onWsError(Object error) {
    print('❌ [TRACKING] WS error: $error');
    if (_disposed) return;
    _scheduleReconnectOrFallback();
  }

  void _scheduleReconnectOrFallback() {
    if (_disposed || !isTrackable) return;

    _wsSub?.cancel();
    _wsSub = null;
    _channel = null;

    if (_reconnectAttempt >= _backoffSeconds.length) {
      // Stop retrying WS for now; keep the map alive via REST polling.
      _startPollingFallback();
      return;
    }

    connectionState.value = TrackingConnectionState.connecting;
    final delay = _backoffSeconds[_reconnectAttempt];
    _reconnectAttempt++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (!_disposed && isTrackable) _connectWebSocket();
    });
  }

  // ── REST fallback polling ────────────────────────────────────
  void _startPollingFallback() {
    if (_disposed) return;
    connectionState.value = TrackingConnectionState.fallbackPolling;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (!isTrackable) {
        _teardown();
        connectionState.value = TrackingConnectionState.stopped;
        return;
      }
      await _loadInitial();
      // Periodically try to upgrade back to WebSocket.
      if (_channel == null) {
        _reconnectAttempt = 0;
        _connectWebSocket();
      }
    });
  }

  void _stopPollingFallback() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _teardown() {
    _wsSub?.cancel();
    _wsSub = null;
    _channel?.sink.close(ws_status.goingAway);
    _channel = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Turns your existing REST base URL into the matching WS one:
  /// https://api.yourdomain.com → wss://api.yourdomain.com
  /// http://localhost:8000      → ws://localhost:8000
  static String _wsBaseUrl(String httpBaseUrl) {
    final uri = Uri.parse(httpBaseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$wsScheme://${uri.authority}';
  }
}