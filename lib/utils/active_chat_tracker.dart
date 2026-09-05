import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// ✅ Синглтон для отслеживания активного чата с поддержкой lifecycle
/// Это нужно, чтобы не инкрементировать счетчик непрочитанных сообщений
/// для чата, в котором пользователь находится прямо сейчас
class ActiveChatTracker with WidgetsBindingObserver {
  static final ActiveChatTracker _instance = ActiveChatTracker._internal();
  factory ActiveChatTracker() => _instance;
  
  ActiveChatTracker._internal() {
    // ✅ Подписываемся на изменения жизненного цикла приложения
    WidgetsBinding.instance.addObserver(this);
  }

  // ✅ ИСПРАВЛЕНО: Используем uniqueId вместо id для привязки чатов
  String? _activeChatUniqueId;
  int? _activeChatId;
  DateTime? _lastSetTime; // ✅ Для отслеживания "свежести" установки
  bool _isAppInForeground = true; // ✅ Приложение на переднем плане?

  /// ✅ Устанавливаем uniqueId открытого чата
  /// Вызывается когда пользователь заходит в чат
  void setActiveChat(String? chatUniqueId, {int? chatId}) {
    final previousChatUniqueId = _activeChatUniqueId;
    _activeChatUniqueId = chatUniqueId;
    _activeChatId = chatId;
    _lastSetTime = DateTime.now();
    
    if (previousChatUniqueId != null && previousChatUniqueId != chatUniqueId) {
      debugPrint('=================-=== ⚠️ ActiveChatTracker: Switched from chat $previousChatUniqueId to $chatUniqueId');
    } else {
      debugPrint('=================-=== ✅ ActiveChatTracker: Chat $chatUniqueId is now ACTIVE');
    }
  }

  /// ✅ Убираем активный чат (пользователь вышел)
  /// Вызывается когда пользователь выходит из чата
  /// [chatUniqueId] - опциональный параметр для защиты от race condition при быстром переключении
  void clearActiveChat([String? chatUniqueId, int? chatId]) {
    // ✅ ВАЖНО: Очищаем только если это действительно текущий активный чат
    // Защита от race condition при быстром переключении
    final uniqueIdMismatch =
        chatUniqueId != null && _activeChatUniqueId != chatUniqueId;
    final chatIdMismatch = chatId != null && _activeChatId != chatId;
    if (uniqueIdMismatch && chatIdMismatch) {
      debugPrint('=================-=== ⚠️ ActiveChatTracker: Ignoring clear for chat $chatUniqueId (current active: $_activeChatUniqueId)');
      return;
    }
    if (uniqueIdMismatch && chatId == null) {
      debugPrint('=================-=== ⚠️ ActiveChatTracker: Ignoring clear for chat $chatUniqueId (current active: $_activeChatUniqueId)');
      return;
    }
    if (chatUniqueId == null && chatIdMismatch) {
      debugPrint('=================-=== ⚠️ ActiveChatTracker: Ignoring clear for chat id $chatId (current active: $_activeChatId)');
      return;
    }
    
    if (_activeChatUniqueId != null || _activeChatId != null) {
      debugPrint('❌ ActiveChatTracker: Chat $_activeChatUniqueId is now INACTIVE');
    }
    _activeChatUniqueId = null;
    _activeChatId = null;
    _lastSetTime = null;
  }

  /// ✅ Проверяем, открыт ли конкретный чат по uniqueId
  /// Возвращает true если пользователь сейчас находится внутри этого чата
  bool isChatActive(String? chatUniqueId, {int? chatId}) {
    // ✅ Если приложение в фоне - чат технически неактивен
    if (!_isAppInForeground) {
      return false;
    }

    final matchesUniqueId = chatUniqueId != null &&
        _activeChatUniqueId != null &&
        _activeChatUniqueId == chatUniqueId;
    final matchesChatId =
        chatId != null && _activeChatId != null && _activeChatId == chatId;

    if (!matchesUniqueId && !matchesChatId) {
      return false;
    }
    
    // ✅ Дополнительная проверка: если прошло больше 5 секунд с момента установки,
    // возможно что-то пошло не так (dispose не вызвался)
    if (_lastSetTime != null) {
      final elapsed = DateTime.now().difference(_lastSetTime!);
      if (elapsed > Duration(seconds: 5)) {
        debugPrint('=================-=== ⚠️ ActiveChatTracker: Chat $chatUniqueId active for ${elapsed.inSeconds}s - possible stale state');
        // Не очищаем автоматически, но логируем для отладки
      }
    }
    
    return true;
  }

  /// ✅ Получаем uniqueId активного чата (может быть null если ни один чат не открыт)
  String? get activeChatUniqueId => _isAppInForeground ? _activeChatUniqueId : null;

  /// ✅ НОВОЕ: Обработка изменений жизненного цикла приложения
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Приложение вернулось на передний план
        _isAppInForeground = true;
        debugPrint('🟢 ActiveChatTracker: App RESUMED (active chat: $_activeChatUniqueId)');
        break;
        
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // Приложение ушло в фон или свернулось
        _isAppInForeground = false;
        debugPrint('🟡 ActiveChatTracker: App PAUSED/INACTIVE (active chat: $_activeChatUniqueId)');
        break;
        
      case AppLifecycleState.detached:
        // Приложение закрывается
        _isAppInForeground = false;
        debugPrint('🔴 ActiveChatTracker: App DETACHED');
        clearActiveChat();
        break;
        
      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        debugPrint('🟡 ActiveChatTracker: App HIDDEN');
        break;
    }
  }

  /// ✅ НОВОЕ: Принудительная очистка (для экстренных случаев)
  void forceReset() {
    debugPrint('=================-=== 🔄 ActiveChatTracker: FORCE RESET');
    _activeChatUniqueId = null;
    _activeChatId = null;
    _lastSetTime = null;
  }

  /// Очистка при уничтожении (хотя синглтон и не уничтожается)
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

