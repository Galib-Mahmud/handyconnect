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

  // ── Set via constructor ──────────────────────────────────────────
  final int    requestId;
  final String clientName;
  final String jobLabel;
  final String clientPhoto;
  final String myFullName;

  ProfessionalChatController({
    required this.requestId,
    required this.clientName,
    required this.jobLabel,
    required this.clientPhoto,
    required this.myFullName,
  });

  // remove the late final fields and the args parsing block in onInit
  // rename _myFullName usages → myFullName

  // ── Reactive state ───────────────────────────────────────────────
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading             = false.obs;
  final RxBool isConnected           = false.obs;

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
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('💬 [CHAT] Controller init');
    print('   requestId : $requestId');
    print('   clientName: $clientName');
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
      print('✅ [CHAT] History: ${messages.length} message(s)');
      _scrollToBottom();
    } catch (e) {
      print('❌ [CHAT] History fetch failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _connectWebSocket() {
    print('🔍 [WS] Connecting — requestId=$requestId  disposed=$_disposed');
    if (requestId == 0 || _disposed) return;

    try {
      final token = UserInfo.getAccessTokenSync() ?? '';
      if (token.isEmpty) { print('⚠️ [WS] No token'); return; }

      _pingTimer?.cancel();
      _wsSub?.cancel();
      try { _channel?.sink.close(); } catch (_) {}

      final wsUri = Uri.parse(
          '${ApiEndpoint.chatWebSocket(requestId)}?token=$token');
      print('🔌 [WS] → $wsUri');

      _channel = WebSocketChannel.connect(wsUri);

      _wsSub = _channel!.stream.listen(
            (data) {
          if (!isConnected.value) {
            isConnected.value = true;
            _retryCount       = 0;
            print('✅ [WS] Connected — request $requestId');
            _flushPendingQueue();
            _startPingTimer();
          }
          _onWsMessage(data);
        },
        onError      : _onWsError,
        onDone       : _onWsDone,
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