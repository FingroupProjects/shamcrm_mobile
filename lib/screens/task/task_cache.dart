import 'dart:convert';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskCache {
  static const String _cachedTaskStatusesKey = 'cachedTaskStatuses';

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
  static Future<void> cacheTasksForStatus(int? statusId, List<Task> tasks) async {
    if (statusId == null) return;
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedTasks_$statusId';
    
    try {
      final String encodedTasks = json.encode(tasks.map((task) => task.toJson()).toList());
      await prefs.setString(key, encodedTasks);
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

  // Очистить все кэшированные задачи
  static Future<void> clearAllTasks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final taskKeys = keys.where((key) => key.startsWith('cachedTasks_')).toList();
    
    for (var key in taskKeys) {
      await prefs.remove(key);
    }
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
}