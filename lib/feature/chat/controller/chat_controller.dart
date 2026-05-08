// lib/features/professional/chat/controller/professional_chat_controller.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../../../../../core/endpoint/api_client.dart';
import '../../../../../core/endpoint/api_endpoint.dart';
import '../../../../../core/local_storage/user_info.dart';

// ── Model ──────────────────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isSentByMe;
  final String time;
  final String? status;
  final String? sender;

  ChatMessage({
    required this.text,
    required this.isSentByMe,
    required this.time,
    this.status,
    this.sender,
  });

  /// From REST history  GET /api/requests/{id}/messages/
  factory ChatMessage.fromJson(Map<String, dynamic> json, String myName) {
    final sender   = (json['sender_name'] ?? json['sender'] ?? '') as String;
    final sentByMe = sender == myName;
    final ts       = json['timestamp'] as String? ?? '';
    String time    = '';
    if (ts.isNotEmpty) {
      try {
        final dt = DateTime.parse(ts).toLocal();
        time = '${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        time = ts;
      }
    }
    return ChatMessage(
      text      : (json['message'] ?? json['text'] ?? '') as String,
      isSentByMe: sentByMe,
      time      : time,
      sender    : sender,
    );
  }

  /// From WebSocket broadcast  { "message": "...", "sender": "Full Name" }
  factory ChatMessage.fromWs(Map<String, dynamic> json, String myFullName) {
    final sender   = (json['sender'] ?? '') as String;
    final sentByMe = sender == myFullName;
    final now      = TimeOfDay.now();
    final time     = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    return ChatMessage(
      text      : (json['message'] ?? '') as String,
      isSentByMe: sentByMe,
      time      : time,
      sender    : sender,
      status    : sentByMe ? 'Sent' : null,
    );
  }
}

// ── Controller ─────────────────────────────────────────────────────
class ProfessionalChatController extends GetxController {
  final ApiClient _apiClient = ApiClient(baseUrl: ApiEndpoint.baseUrl);

  // ── Args (set in onInit) ───────────────────────────────────────────
  late final int    requestId;
  late final String clientName;
  late final String jobLabel;
  late final String clientPhoto;
  String _myFullName = '';

  // ── Reactive state ─────────────────────────────────────────────────
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading             = false.obs;
  final RxBool isConnected           = false.obs;

  final TextEditingController textController   = TextEditingController();
  final ScrollController      scrollController = ScrollController();

  // ── WebSocket internals ────────────────────────────────────────────
  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  Timer? _pingTimer;
  bool _disposed   = false;
  int  _retryCount = 0;
  static const int _maxRetries = 8;

  // Messages queued while socket is reconnecting
  final List<String> _pendingQueue = [];

  // ─────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    final args  = Get.arguments as Map<String, dynamic>? ?? {};
    requestId   = (args['requestId']   as int?)    ?? 0;
    clientName  = (args['clientName']  as String?) ?? 'Customer';
    jobLabel    = (args['jobLabel']    as String?) ?? 'Job';
    clientPhoto = (args['clientPhoto'] as String?) ?? '';
    _myFullName = (args['myName']      as String?) ?? '';

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('💬 [CHAT] Controller init');
    print('   requestId : $requestId');
    print('   clientName: $clientName');
    print('   myName    : $_myFullName');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _fetchHistory();
    _connectWebSocket();
  }

  @override
  void onClose() {
    _disposed = true;
    _pingTimer?.cancel();
    _wsSub?.cancel();
    try { _channel?.sink.close(ws_status.goingAway); } catch (_) {}
    textController.dispose();
    scrollController.dispose();
    print('🔴 [CHAT] Controller closed — WS disconnected');
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 1 — REST: fetch message history
  // GET /api/requests/{id}/messages/
  // ─────────────────────────────────────────────────────────────────
  Future<void> fetchHistory() => _fetchHistory();

  Future<void> _fetchHistory() async {
    if (requestId == 0) return;
    try {
      isLoading.value = true;
      print('📥 [CHAT] Fetching history — requestId: $requestId');

      final res = await _apiClient.get(
        ApiEndpoint.chatMessages(requestId),
        requiresAuth: true,
      );

      final List<dynamic> raw =
      res is List ? res : (res['results'] as List? ?? []);

      messages.assignAll(
        raw.map((e) => ChatMessage.fromJson(
            Map<String, dynamic>.from(e as Map), _myFullName)),
      );

      print('✅ [CHAT] History loaded — ${messages.length} message(s)');
      _scrollToBottom();
    } catch (e) {
      print('❌ [CHAT] History fetch failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 2 — WebSocket connect
  // ws://<domain>/ws/chat/<request_id>/?token=<jwt>
  //
  // Rules from backend docs:
  //  • Use WebSocketChannel.connect() — NOT IOWebSocketChannel
  //  • Token in query string ONLY — no custom headers
  //  • Ping every 30s to prevent mobile disconnection
  // ─────────────────────────────────────────────────────────────────
  void _connectWebSocket() {
    if (requestId == 0 || _disposed) return;

    try {
      final token = UserInfo.getAccessTokenSync() ?? '';
      if (token.isEmpty) {
        print('⚠️  [WS] No token — aborting');
        return;
      }

      // Tear down previous connection cleanly
      _pingTimer?.cancel();
      _wsSub?.cancel();
      try { _channel?.sink.close(); } catch (_) {}

      // Build URI: ws://<domain>/ws/chat/<id>/?token=<jwt>
      final wsUri = Uri.parse(
        '${ApiEndpoint.chatWebSocket(requestId)}?token=$token',
      );
      print('🔌 [WS] Connecting → $wsUri');

      // WebSocketChannel.connect() as specified in backend docs
      _channel = WebSocketChannel.connect(wsUri);

      // Listen BEFORE marking connected so no messages are missed
      _wsSub = _channel!.stream.listen(
        _onWsMessage,
        onError      : _onWsError,
        onDone       : _onWsDone,
        cancelOnError: false,
      );

      // Mark connected immediately after listen is attached
      isConnected.value = true;
      _retryCount       = 0;
      print('✅ [WS] Connected — request $requestId');

      // Flush any messages that were queued during reconnect
      _flushPendingQueue();

      // Ping every 30s to keep connection alive on mobile (backend docs note 3)
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (isConnected.value && _channel != null) {
          try {
            _channel!.sink.add(jsonEncode({'type': 'ping'}));
            print('🏓 [WS] Ping sent');
          } catch (_) {}
        }
      });
    } catch (e) {
      print('❌ [WS] Connect error: $e');
      isConnected.value = false;
      _scheduleReconnect();
    }
  }

  // ── Incoming message from server ──────────────────────────────────
  void _onWsMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;

      // Ignore ping/pong frames
      if (data['type'] == 'ping' || data['type'] == 'pong') return;

      print('📨 [WS] Received: $data');

      final msg = ChatMessage.fromWs(data, _myFullName);

      // Only add messages from the other party — ours are already
      // added optimistically in sendMessage()
      if (!msg.isSentByMe) {
        messages.add(msg);
        _scrollToBottom();
      }
    } catch (e) {
      print('❌ [WS] Parse error: $e');
    }
  }

  void _onWsError(dynamic error) {
    print('❌ [WS] Error: $error');
    isConnected.value = false;
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  void _onWsDone() {
    print('🔌 [WS] Connection closed');
    isConnected.value = false;
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  // Exponential back-off: 2s, 4s, 6s … capped at 30s
  void _scheduleReconnect() {
    if (_disposed || _retryCount >= _maxRetries) {
      print('🛑 [WS] Max retries reached — giving up');
      return;
    }
    _retryCount++;
    final delay = Duration(seconds: (_retryCount * 2).clamp(2, 30));
    print('🔄 [WS] Retry #$_retryCount in ${delay.inSeconds}s');
    Future.delayed(delay, () {
      if (!_disposed) _connectWebSocket();
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // Send message
  // Payload: { "message": "..." }
  // ─────────────────────────────────────────────────────────────────
  void sendMessage() {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    // Optimistic UI update — show immediately
    final now  = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    messages.add(ChatMessage(
      text      : text,
      isSentByMe: true,
      time      : time,
      status    : 'Sent',
      sender    : _myFullName,
    ));
    textController.clear();
    _scrollToBottom();

    if (isConnected.value && _channel != null) {
      _sendViaSocket(text);
    } else {
      // Queue — will be sent when socket reconnects
      print('⏳ [WS] Not connected — queuing: "$text"');
      _pendingQueue.add(text);
      _connectWebSocket(); // attempt immediate reconnect
    }
  }

  void _sendViaSocket(String text) {
    try {
      _channel!.sink.add(jsonEncode({'message': text}));
      print('📤 [WS] Sent: "$text"');
    } catch (e) {
      print('❌ [WS] Send failed: $e');
      _pendingQueue.insert(0, text);
      isConnected.value = false;
      _pingTimer?.cancel();
      _scheduleReconnect();
    }
  }

  void _flushPendingQueue() {
    if (_pendingQueue.isEmpty) return;
    print('📬 [WS] Flushing ${_pendingQueue.length} queued message(s)');
    final copy = List<String>.from(_pendingQueue);
    _pendingQueue.clear();
    for (final text in copy) {
      _sendViaSocket(text);
    }
  }

  // ── Scroll helper ──────────────────────────────────────────────────
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients &&
          scrollController.position.hasContentDimensions) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve   : Curves.easeOut,
        );
      }
    });
  }
}