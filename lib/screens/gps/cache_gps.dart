import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static const String _pendingGpsKey = 'pending_gps';
  static const String _gpsLogsKey = 'gps_logs';
  static const int _maxPendingSize = 1000; // Максимум 1000 записей в кэше
  static const int _maxLogSize = 200; // Увеличили до 200 логов

  // Сохраняем данные геолокации в кэш
  Future<void> saveGpsData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList(_pendingGpsKey) ?? [];
    
    // Добавляем timestamp при сохранении в кэш, если его нет
    final dataWithTimestamp = Map<String, dynamic>.from(data);
    if (!dataWithTimestamp.containsKey('cached_at')) {
      dataWithTimestamp['cached_at'] = DateTime.now().toIso8601String();
    }
    
    pending.add(jsonEncode(dataWithTimestamp));
    
    // Ограничиваем размер кэша
    if (pending.length > _maxPendingSize) {
      pending = pending.sublist(pending.length - _maxPendingSize);
    }
    await prefs.setStringList(_pendingGpsKey, pending);
    print('Cache: Saved GPS data: $dataWithTimestamp');
    
    // Сохраняем лог о кэшировании
    await saveLog({
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': data['user_id'] ?? 'unknown',
      'latitude': data['latitude'] ?? '0',
      'longitude': data['longitude'] ?? '0',
      'status': 'cached',
      'action': 'Data saved to cache',
      'details': 'Location data cached due to no internet or sending failure'
    });
  }

  // Получаем все накопленные данные
  Future<List<Map<String, dynamic>>> getPendingGpsData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList(_pendingGpsKey) ?? [];
    return pending
        .map((str) {
          try {
            return Map<String, dynamic>.from(jsonDecode(str));
          } catch (e) {
            print('Cache: Error decoding pending data: $e, data: $str');
            return null;
          }
        })
        .where((data) => data != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  // Очищаем отправленные данные
  Future<void> clearPendingGpsData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pendingGpsKey, []);
    print('Cache: Cleared pending GPS data');
  }

  // Сохраняем лог с улучшенной структурой
  Future<void> saveLog(Map<String, dynamic> log) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(_gpsLogsKey) ?? [];
    
    // Убеждаемся, что у лога есть все необходимые поля
    final enhancedLog = {
      'timestamp': log['timestamp'] ?? DateTime.now().toIso8601String(),
      'user_id': log['user_id'] ?? 'unknown',
      'latitude': log['latitude'] ?? '0',
      'longitude': log['longitude'] ?? '0',
      'status': log['status'] ?? 'unknown',
      'action': log['action'] ?? 'GPS operation',
      'details': log['details'] ?? '',
      'response': log['response'],
      'error': log['error'],
      'server_response': log['server_response'],
      'http_code': log['http_code'],
    };
    
    logs.add(jsonEncode(enhancedLog));
    
    // Ограничиваем размер логов
    if (logs.length > _maxLogSize) {
      logs = logs.sublist(logs.length - _maxLogSize);
    }
    await prefs.setStringList(_gpsLogsKey, logs);
    print('Cache: Saved log: $enhancedLog');
  }

  // Получаем все логи
  Future<List<Map<String, dynamic>>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logStrings = prefs.getStringList(_gpsLogsKey) ?? [];
    
    final logs = logStrings
        .map((str) {
          try {
            return Map<String, dynamic>.from(jsonDecode(str));
          } catch (e) {
            print('Cache: Error decoding log: $e, log: $str');
            return null;
          }
        })
        .where((log) => log != null)
        .cast<Map<String, dynamic>>()
        .toList();
    
    // Сортируем по времени (новые сверху)
    logs.sort((a, b) {
      try {
        final aTime = DateTime.parse(a['timestamp'] ?? '');
        final bTime = DateTime.parse(b['timestamp'] ?? '');
        return bTime.compareTo(aTime);
      } catch (e) {
        return 0;
      }
    });
    
    print('Cache: Retrieved ${logs.length} logs');
    return logs;
  }

  // Очищаем логи
  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_gpsLogsKey, []);
    print('Cache: Cleared logs');
  }

  // Добавляем метод для получения статистики
  Future<Map<String, int>> getLogsStatistics() async {
    final logs = await getLogs();
    final stats = <String, int>{};
    
    for (final log in logs) {
      final status = log['status'] ?? 'unknown';
      stats[status] = (stats[status] ?? 0) + 1;
    }
    
    return stats;
  }
}