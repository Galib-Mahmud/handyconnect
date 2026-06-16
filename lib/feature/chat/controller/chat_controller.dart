// lib/features/professional/chat/controller/professional_chat_controller.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:handyConnect/core/endpoint/api_client.dart';
import 'package:handyConnect/core/endpoint/api_endpoint.dart';
import 'package:handyConnect/core/local_storage/user_info.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

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

  /// From REST history  GET /api/services/requests/{id}/messages/
  /// API fields: content, is_me, sender_name, timestamp
  factory ChatMessage.fromJson(Map<String, dynamic> json, String myName) {
    final ts = json['timestamp'] as String? ?? '';
    String time = '';
    if (ts.isNotEmpty) {
      try {
        final dt = DateTime.parse(ts).toLocal();
        time = '${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        time = ts;
      }
    }
    final bool sentByMe = json['is_me'] == true;
    return ChatMessage(
      text      : (json['content'] ?? json['message'] ?? json['text'] ?? '') as String,
      isSentByMe: sentByMe,
      time      : time,
      sender    : (json['sender_name'] ?? '') as String,
      status    : sentByMe ? 'Sent' : null,
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
      text      : (json['message'] ?? json['content'] ?? '') as String,
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

  // ── Set via constructor ──────────────────────────────────────────
  final int    requestId;
  final String clientNameArg;
  final String jobLabel;
  final String clientPhoto;
  final String myFullName;

  ProfessionalChatController({
    required this.requestId,
    String clientName = 'Chat',
    this.jobLabel = 'Service Request',
    this.clientPhoto = '',
    required this.myFullName,
  }) : clientNameArg = clientName;

  // ── Reactive state ───────────────────────────────────────────────
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool   isLoading   = false.obs;
  final RxBool   isConnected = false.obs;
  // Opposite party-r naam — history load hole automatically set hobe
  final RxString clientName  = ''.obs;

  final TextEditingController textController   = TextEditingController();
  final ScrollController      scrollController = ScrollController();

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  Timer? _pingTimer;
  bool _disposed   = false;
  int  _retryCount = 0;
  static const int _maxRetries = 8;
  final List<String> _pendingQueue = [];

  @override
  void onInit() {
    super.onInit();
    clientName.value = clientNameArg;
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('💬 [CHAT] Controller init');
    print('   requestId : $requestId');
    print('   myName    : $myFullName');
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
    print('🔴 [CHAT] Controller closed');
    super.onClose();
  }

  Future<void> fetchHistory() => _fetchHistory();

  Future<void> _fetchHistory() async {
    if (requestId == 0) return;
    try {
      isLoading.value = true;
      final res = await _apiClient.get(
        ApiEndpoint.chatMessages(requestId),
        requiresAuth: true,
      );
      final List<dynamic> raw =
      res is List ? res : (res['results'] as List? ?? []);
      messages.assignAll(
        raw.map((e) => ChatMessage.fromJson(
            Map<String, dynamic>.from(e as Map), myFullName)),
      );
      _resolveClientName(raw);
      print('✅ [CHAT] History: ${messages.length} message(s)');
      _scrollToBottom();
    } catch (e) {
      print('❌ [CHAT] History fetch failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// History theke opposite party-r naam ber kore set kore.
  /// is_me == false jonner prothom sender_name = opposite party.
  void _resolveClientName(List<dynamic> raw) {
    for (final e in raw) {
      final m = Map<String, dynamic>.from(e as Map);
      if (m['is_me'] == false) {
        final name = (m['sender_name'] ?? '').toString();
        if (name.isNotEmpty) {
          clientName.value = name;
          break;
        }
      }
    }
  }
  void _connectWebSocket() {
    print('🔍 [WS] Connecting — requestId=$requestId  disposed=$_disposed');
    if (requestId == 0 || _disposed) return;

    final token = UserInfo.getAccessTokenSync() ?? '';
    if (token.isEmpty) {
      print('⚠️ [WS] No token');
      return;
    }

    _pingTimer?.cancel();
    _wsSub?.cancel();
    try { _channel?.sink.close(); } catch (_) {}

    final wsUri = Uri.parse(
        '${ApiEndpoint.chatWebSocket(requestId)}?token=$token');
    print('🔌 [WS] → $wsUri');

    try {
      _channel = WebSocketChannel.connect(wsUri);

      // ✅ Handshake success = connected. Set isConnected HERE.
      _channel!.ready.then((_) {
        if (_disposed) return;
        print('🤝 [WS] Handshake OK — connected!');
        isConnected.value = true;
        _retryCount = 0;
        _flushPendingQueue();
        _startPingTimer();
      }).catchError((e) {
        print('❌ [WS] Handshake failed: $e');
        isConnected.value = false;
        _pingTimer?.cancel();
        _scheduleReconnect();
      });

      // Stream listener — ONLY for receiving messages
      _wsSub = _channel!.stream.listen(
            (data) => _onWsMessage(data),
        onError: _onWsError,
        onDone: _onWsDone,
        cancelOnError: false,
      );
    } catch (e) {
      print('❌ [WS] Connect error: $e');
      isConnected.value = false;
      _scheduleReconnect();
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isConnected.value && _channel != null) {
        try { _channel!.sink.add(jsonEncode({'type': 'ping'})); } catch (_) {}
      }
    });
  }

  void _onWsMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      if (data['type'] == 'ping' || data['type'] == 'pong') return;
      print('📨 [WS] Received: $data');
      final msg = ChatMessage.fromWs(data, myFullName);
      if (!msg.isSentByMe) {
        messages.add(msg);
        // opposite party naam jana na thakle WS theke nao
        if (clientName.value.isEmpty ||
            clientName.value == 'Chat') {
          final s = (data['sender'] ?? '').toString();
          if (s.isNotEmpty) clientName.value = s;
        }
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
    print('🔌 [WS] Closed');
    isConnected.value = false;
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _retryCount >= _maxRetries) return;
    _retryCount++;
    final delay = Duration(seconds: (_retryCount * 2).clamp(2, 30));
    print('🔄 [WS] Retry #$_retryCount in ${delay.inSeconds}s');
    Future.delayed(delay, () { if (!_disposed) _connectWebSocket(); });
  }

  void sendMessage() {
    final text = textController.text.trim();
    if (text.isEmpty) return;
    print('🔍 [CHAT] sendMessage — requestId=$requestId  isConnected=${isConnected.value}');

    final now  = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    messages.add(ChatMessage(
      text: text, isSentByMe: true,
      time: time, status: 'Sent', sender: myFullName,
    ));
    textController.clear();
    _scrollToBottom();

    if (isConnected.value && _channel != null) {
      _sendViaSocket(text);
    } else {
      print('⏳ [WS] Not connected — queuing: "$text"');
      _pendingQueue.add(text);
      _connectWebSocket();
    }
  }

  void _sendViaSocket(String text) {
    final payload = jsonEncode({'message': text});
    try {
      _channel!.sink.add(payload);
      print('📤 [WS] Sent: $payload');
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
    final copy = List<String>.from(_pendingQueue);
    _pendingQueue.clear();
    for (final text in copy) { _sendViaSocket(text); }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients &&
          scrollController.position.hasContentDimensions) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}