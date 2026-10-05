import 'dart:async';

import 'package:flutter/foundation.dart';

/// Отправляет `readMessages` один раз на один `up_to_message_id`.
///
/// Экран чата зовёт отметку «прочитано» с каждого кадра скролла и с каждого
/// состояния ленты. Раньше запрос уходил пачкой, пока первый ответ не вернулся.
/// Сервер на каждый такой POST делает UPDATE и бродкаст `chat.read`.
class ChatReadMarker {
  ChatReadMarker({
    required this.send,
    this.debounce = const Duration(milliseconds: 400),
  });

  /// Сетевой вызов. Бросает ошибку, если сервер не принял отметку.
  final Future<void> Function(int messageId) send;

  /// Ждём короткую паузу, чтобы из пачки id ушёл только самый новый.
  final Duration debounce;

  int? _coveredUpTo;
  int? _queuedId;
  bool _inFlight = false;
  Timer? _debounceTimer;
  Future<void>? _activeFlush;

  /// Этот id уже ушёл на сервер или сейчас уходит.
  bool covers(int messageId) =>
      _coveredUpTo != null && messageId <= _coveredUpTo!;

  /// Схлопывает повторные вызовы. Один и тот же id сеть не трогает.
  void request(int messageId) {
    if (!_queue(messageId)) return;
    if (_inFlight) return;
    // Таймер не сдвигаем: иначе непрерывный поток сообщений никогда не уйдёт.
    if (_debounceTimer?.isActive == true) return;
    _debounceTimer = Timer(debounce, () {
      unawaited(_flush());
    });
  }

  /// Выход из чата: отправить сразу, без ожидания дебаунса.
  /// true — сервер уже знает этот id или запрос прошёл.
  Future<bool> markNow(int messageId) async {
    if (messageId <= 0) return false;
    if (!covers(messageId)) {
      _queue(messageId);
    }
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _flush();
    return covers(messageId);
  }

  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  bool _queue(int messageId) {
    if (messageId <= 0) return false;
    if (covers(messageId)) return false;
    if (_queuedId != null && messageId <= _queuedId!) return false;
    _queuedId = messageId;
    return true;
  }

  Future<void> _flush() {
    final current = _activeFlush;
    if (current != null) return current;
    final run = _drain();
    _activeFlush = run;
    return run.whenComplete(() {
      if (identical(_activeFlush, run)) _activeFlush = null;
    });
  }

  Future<void> _drain() async {
    _inFlight = true;
    try {
      while (true) {
        final messageId = _queuedId;
        _queuedId = null;
        if (messageId == null || covers(messageId)) return;

        // Занимаем id до await, иначе параллельные вызовы уйдут тем же запросом.
        _coveredUpTo = messageId;
        try {
          await send(messageId);
        } catch (error, stackTrace) {
          if (_coveredUpTo == messageId) _coveredUpTo = null;
          debugPrint(
            'ChatReadMarker: readMessages failed for $messageId: $error\n$stackTrace',
          );
          // Тот же id не крутим в цикле. Более новый, если успел прийти, отправляем.
          if (_queuedId == null || _queuedId == messageId) {
            _queuedId = null;
            return;
          }
        }
      }
    } finally {
      _inFlight = false;
    }
  }
}
