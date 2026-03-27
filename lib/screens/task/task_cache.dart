import 'dart:convert';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskCache {
  static const String _cachedTaskStatusesKey = 'cachedTaskStatuses';
  static const String _persistentTaskCountsKey = 'persistentTaskCounts';

  // Сохранить статусы задач в кэш
  static Future<void> cacheTaskStatuses(List<Map<String, dynamic>> taskStatuses) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Валидируем данные перед сохранением
    final validStatuses = taskStatuses.where((status) {
      return status['id'] != null && 
             status['title'] != null && 
             status['title'].toString().isNotEmpty;
    }).toList();
    
    if (validStatuses.isEmpty) {
      return; // Не сохраняем невалидные данные
    }
    
    final String encodedStatuses = json.encode(validStatuses);
    await prefs.setString(_cachedTaskStatusesKey, encodedStatuses);
  }

  // Получить статусы задач из кэша с валидацией
  static Future<List<Map<String, dynamic>>> getTaskStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedTaskStatusesKey);
    
    if (cachedStatuses != null && cachedStatuses.isNotEmpty) {
      try {
        final List<dynamic> decodedData = json.decode(cachedStatuses);
        
        // Валидируем данные при чтении
        final validStatuses = decodedData
            .where((status) => 
                status is Map && 
                status['id'] != null && 
                status['title'] != null &&
                status['title'].toString().isNotEmpty)
            .map((status) => Map<String, dynamic>.from(status))
            .toList();
        
        return validStatuses;
      } catch (e) {
        // Если данные повреждены, очищаем кэш
        await prefs.remove(_cachedTaskStatusesKey);
        return [];
      }
    }
    return [];
  }

  // Сохранить задачи для определенного статуса в кэш
  static Future<void> cacheTasksForStatus(
    int? statusId, 
    List<Task> tasks, {
    bool updatePersistentCount = false,
    int? actualTotalCount,
  }) async {
    if (statusId == null) return;
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedTasks_$statusId';
    
    try {
      final String encodedTasks = json.encode(tasks.map((task) => task.toJson()).toList());
      await prefs.setString(key, encodedTasks);
      
      // КРИТИЧНО: Обновляем persistent count с РЕАЛЬНЫМ значением из API
      if (updatePersistentCount) {
        final countToSave = actualTotalCount ?? tasks.length;
        await setPersistentTaskCount(statusId, countToSave);
      }
    } catch (e) {
      // Логируем ошибку, но не падаем
      print('Error caching tasks for status $statusId: $e');
    }
  }

  // Получить задачи для определенного статуса из кэша
  static Future<List<Task>> getTasksForStatus(int? statusId) async {
    if (statusId == null) return [];
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedTasks_$statusId';
    final String? cachedTasks = prefs.getString(key);

    if (cachedTasks != null && cachedTasks.isNotEmpty) {
      try {
        final List<dynamic> decodedData = json.decode(cachedTasks);
        return decodedData.map((task) => Task.fromJson(task, statusId)).toList();
      } catch (e) {
        // Если данные повреждены, очищаем кэш для этого статуса
        await prefs.remove(key);
        return [];
      }
    }
    return [];
  }

  // ======================== PERSISTENT COUNTS ========================
  
  /// Установить постоянный счётчик задач для статуса
  static Future<void> setPersistentTaskCount(int statusId, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_persistentTaskCountsKey);
    final Map<String, int> counts = countsJson != null
        ? Map<String, int>.from(json.decode(countsJson))
        : {};
    
    counts[statusId.toString()] = count;
    await prefs.setString(_persistentTaskCountsKey, json.encode(counts));
  }
  
  /// Получить постоянный счётчик задач для статуса
  static Future<int> getPersistentTaskCount(int statusId) async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_persistentTaskCountsKey);
    
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
  static Future<Map<String, int>> getPersistentTaskCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final countsJson = prefs.getString(_persistentTaskCountsKey);
    
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
    await prefs.remove(_persistentTaskCountsKey);
  }
  
  /// Обновить счётчики при перемещении задачи
  static Future<void> updateTaskCountTemporary(int oldStatusId, int newStatusId) async {
    final oldCount = await getPersistentTaskCount(oldStatusId);
    final newCount = await getPersistentTaskCount(newStatusId);
    
    await setPersistentTaskCount(oldStatusId, oldCount > 0 ? oldCount - 1 : 0);
    await setPersistentTaskCount(newStatusId, newCount + 1);
  }

  // Очистить все кэшированные задачи
  static Future<void> clearAllTasks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final taskKeys = keys.where((key) => key.startsWith('cachedTasks_')).toList();
    
    for (var key in taskKeys) {
      await prefs.remove(key);
    }
  }
  
  /// Очистить задачи для конкретного статуса
  static Future<void> clearTasksForStatus(int statusId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cachedTasks_$statusId');
  }

  // Очистить кэшированные статусы задач и задачи
  static Future<void> clearTaskStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedTaskStatusesKey);

    List<dynamic> decodedData = [];

    if (cachedStatuses != null) {
      try {
        decodedData = json.decode(cachedStatuses);
      } catch (e) {
        // Игнорируем ошибки при декодировании
      }
    }

    await prefs.remove(_cachedTaskStatusesKey);

    final Set<int> statusIds = decodedData
        .where((status) => status is Map && status['id'] != null)
        .map<int>((status) => status['id'] as int)
        .toSet();
        
    for (var statusId in statusIds) {
      await prefs.remove('cachedTasks_$statusId');
    }
  }

  // Очистить все кэшированные данные
  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedTaskStatusesKey);
  }
  
  /// РАДИКАЛЬНАЯ очистка ВСЕХ данных
  static Future<void> clearEverything() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Очищаем статусы
    await prefs.remove(_cachedTaskStatusesKey);
    
    // Очищаем все задачи
    final keys = prefs.getKeys();
    final taskKeys = keys.where((key) => key.startsWith('cachedTasks_')).toList();
    for (var key in taskKeys) {
      await prefs.remove(key);
    }
    
    // Очищаем persistent counts
    await prefs.remove(_persistentTaskCountsKey);
  }
  
  /// Очистить все данные с сохранением persistent counts
  static Future<void> clearAllData() async {
    await clearTaskStatuses();
    await clearAllTasks();
    // НЕ удаляем persistent counts!
  }
}