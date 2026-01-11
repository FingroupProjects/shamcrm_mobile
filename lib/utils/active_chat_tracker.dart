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

  int? _activeChatId;
  DateTime? _lastSetTime; // ✅ Для отслеживания "свежести" установки
  bool _isAppInForeground = true; // ✅ Приложение на переднем плане?

  /// ✅ Устанавливаем ID открытого чата
  /// Вызывается когда пользователь заходит в чат
  void setActiveChat(int chatId) {
    final previousChatId = _activeChatId;
    _activeChatId = chatId;
    _lastSetTime = DateTime.now();
    
    if (previousChatId != null && previousChatId != chatId) {
      debugPrint('⚠️ ActiveChatTracker: Switched from chat $previousChatId to $chatId');
    } else {
      debugPrint('✅ ActiveChatTracker: Chat $chatId is now ACTIVE');
    }
  }

  /// ✅ Убираем активный чат (пользователь вышел)
  /// Вызывается когда пользователь выходит из чата
  /// [chatId] - опциональный параметр для защиты от race condition при быстром переключении
  void clearActiveChat([int? chatId]) {
    // ✅ ВАЖНО: Очищаем только если это действительно текущий активный чат
    // Защита от race condition при быстром переключении
    if (chatId != null && _activeChatId != chatId) {
      debugPrint('⚠️ ActiveChatTracker: Ignoring clear for chat $chatId (current active: $_activeChatId)');
      return;
    }
    
    if (_activeChatId != null) {
      debugPrint('❌ ActiveChatTracker: Chat $_activeChatId is now INACTIVE');
    }
    _activeChatId = null;
    _lastSetTime = null;
  }

  /// ✅ Проверяем, открыт ли конкретный чат
  /// Возвращает true если пользователь сейчас находится внутри этого чата
  bool isChatActive(int chatId) {
    // ✅ Если приложение в фоне - чат технически неактивен
    if (!_isAppInForeground) {
      return false;
    }
    
    // ✅ Если это не текущий активный чат
    if (_activeChatId != chatId) {
      return false;
    }
    
    // ✅ Дополнительная проверка: если прошло больше 5 секунд с момента установки,
    // возможно что-то пошло не так (dispose не вызвался)
    if (_lastSetTime != null) {
      final elapsed = DateTime.now().difference(_lastSetTime!);
      if (elapsed > Duration(seconds: 5)) {
        debugPrint('⚠️ ActiveChatTracker: Chat $chatId active for ${elapsed.inSeconds}s - possible stale state');
        // Не очищаем автоматически, но логируем для отладки
      }
    }
    
    return true;
  }

  /// ✅ Получаем ID активного чата (может быть null если ни один чат не открыт)
  int? get activeChatId => _isAppInForeground ? _activeChatId : null;

  /// ✅ НОВОЕ: Обработка изменений жизненного цикла приложения
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Приложение вернулось на передний план
        _isAppInForeground = true;
        debugPrint('🟢 ActiveChatTracker: App RESUMED (active chat: $_activeChatId)');
        break;
        
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // Приложение ушло в фон или свернулось
        _isAppInForeground = false;
        debugPrint('🟡 ActiveChatTracker: App PAUSED/INACTIVE (active chat: $_activeChatId)');
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
    debugPrint('🔄 ActiveChatTracker: FORCE RESET');
    _activeChatId = null;
    _lastSetTime = null;
  }

  /// Очистка при уничтожении (хотя синглтон и не уничтожается)
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

