import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter/widgets.dart';

/// Sends `POST /v2/chat/{id}/heartbeat` when a chat is opened and every 30s
/// while the user stays inside that chat. This tells the server the chat is read.
class ChatHeartbeatService with WidgetsBindingObserver {
  ChatHeartbeatService._();

  static final ChatHeartbeatService instance = ChatHeartbeatService._();

  static const Duration interval = Duration(seconds: 30);

  final ApiService _apiService = ApiService();

  Timer? _timer;
  int? _activeChatId;
  bool _isSending = false;
  bool _isObservingLifecycle = false;

  int? get activeChatId => _activeChatId;

  bool get isRunning => _activeChatId != null;

  void start(int chatId) {
    if (chatId <= 0) {
      return;
    }

    if (_activeChatId == chatId && _timer != null) {
      unawaited(_sendHeartbeat());
      return;
    }

    stop();
    _activeChatId = chatId;
    _ensureLifecycleObserver();
    unawaited(_sendHeartbeat());
    _startTimer();
  }

  void stop([int? chatId]) {
    if (chatId != null && _activeChatId != null && _activeChatId != chatId) {
      return;
    }

    _timer?.cancel();
    _timer = null;
    _activeChatId = null;
    _isSending = false;
  }

  void _ensureLifecycleObserver() {
    if (_isObservingLifecycle) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _isObservingLifecycle = true;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      unawaited(_sendHeartbeat());
    });
  }

  Future<void> _sendHeartbeat() async {
    final chatId = _activeChatId;
    if (chatId == null || _isSending) {
      return;
    }

    _isSending = true;
    try {
      await _apiService.sendChatHeartbeat(chatId);
    } catch (e) {
      debugPrint('ChatHeartbeatService: heartbeat failed for chat $chatId: $e');
    } finally {
      _isSending = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_activeChatId == null) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_sendHeartbeat());
        _startTimer();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _timer?.cancel();
        _timer = null;
        break;
      case AppLifecycleState.detached:
        stop();
        break;
    }
  }
}
