import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EventCache {
  static const String _persistentEventCountsKey = 'persistentEventCounts';

  // ======================== PERSISTENT COUNTS ========================
  
  /// Установить постоянный счётчик событий для статуса (1 = активные, 2 = завершённые)
  static Future<void> setPersistentEventCount(int statusId, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_persistentEventCountsKey);
    final Map<String, int> counts = countsJson != null
        ? Map<String, int>.from(json.decode(countsJson))
        : {};
    
    counts[statusId.toString()] = count;
    await prefs.setString(_persistentEventCountsKey, json.encode(counts));
  }
  
  /// Получить постоянный счётчик событий для статуса
  static Future<int> getPersistentEventCount(int statusId) async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_persistentEventCountsKey);
    
    if (countsJson != null) {
      try {
        final Map<String, int> counts = Map<String, int>.from(json.decode(countsJson));
        return counts[statusId.toString()] ?? 0;
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }
  
  /// Получить все постоянные счётчики
  static Future<Map<String, int>> getPersistentEventCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_persistentEventCountsKey);
    
    if (countsJson != null) {
      try {
        return Map<String, int>.from(json.decode(countsJson));
      } catch (e) {
        return {};
      }
    }
    return {};
  }
  
  /// Очистить все постоянные счётчики
  static Future<void> clearPersistentCounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_persistentEventCountsKey);
  }

  /// Очистить события для конкретного статуса
  static Future<void> clearEventsForStatus(int statusId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cachedEvents_$statusId');
  }

  /// Очистить все кэшированные события
  static Future<void> clearAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final eventKeys = keys.where((key) => key.startsWith('cachedEvents_')).toList();
    for (var key in eventKeys) {
      await prefs.remove(key);
    }
  }
  
  /// РАДИКАЛЬНАЯ очистка ВСЕХ данных
  static Future<void> clearEverything() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Очищаем все события
    final keys = prefs.getKeys();
    final eventKeys = keys.where((key) => key.startsWith('cachedEvents_')).toList();
    for (var key in eventKeys) {
      await prefs.remove(key);
    }
    
    // Очищаем persistent counts
    await prefs.remove(_persistentEventCountsKey);
  }
  
  /// Очистить все данные с сохранением persistent counts
  static Future<void> clearAllData() async {
    await clearAllEvents();
    // НЕ удаляем persistent counts!
  }
}