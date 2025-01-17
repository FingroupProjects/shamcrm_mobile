import 'dart:convert';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskCache {
  static const String _cachedTaskStatusesKey = 'cachedTaskStatuses';
  static const String _cachedTasksKey = 'cachedTasks';

  // Сохранить статусы задач в кэш
  static Future<void> cacheTaskStatuses(List<Map<String, dynamic>> taskStatuses) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedStatuses = json.encode(taskStatuses);
    await prefs.setString(_cachedTaskStatusesKey, encodedStatuses);
  }

  // Получить статусы задач из кэша
  static Future<List<Map<String, dynamic>>> getTaskStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedTaskStatusesKey);
    
    if (cachedStatuses != null) {
      final List<dynamic> decodedData = json.decode(cachedStatuses);
      return decodedData.map((status) => Map<String, dynamic>.from(status)).toList();
    }
    return [];
  }

  // Сохранить задачи для определенного статуса в кэш
  static Future<void> cacheTasksForStatus(int? statusId, List<Task> tasks) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedTasks_$statusId';
    final String encodedTasks = json.encode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString(key, encodedTasks);
  }

  // Получить задачи для определенного статуса из кэша
  static Future<List<Task>> getTasksForStatus(int? statusId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedTasks_$statusId';
    final String? cachedTasks = prefs.getString(key);

    if (cachedTasks != null) {
      final List<dynamic> decodedData = json.decode(cachedTasks);
      return decodedData.map((task) => Task.fromJson(task, statusId ?? 0)).toList();
    }
    return [];
  }

  // Очистить все кэшированные задачи
  static Future<void> clearAllTasks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Получаем все ключи из SharedPreferences
    final keys = prefs.getKeys();

    // Фильтруем только те ключи, которые связаны с задачами
    final taskKeys = keys.where((key) => key.startsWith('cachedTasks_')).toList();
    
    // Удаляем все ключи, связанные с задачами
    for (var key in taskKeys) {
      await prefs.remove(key);
      print('Удалены задачи для ключа: $key');
    }

    print('-----------------------------------------------');
    print('УДАЛЕНЫ ВСЕ ЗАДАЧИ ИЗ КЕША !!!');
  }

  // Очистить кэшированные статусы задач и задачи
  static Future<void> clearTaskStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedTaskStatusesKey);

    List<dynamic> decodedData = [];

    if (cachedStatuses != null) {
      decodedData = json.decode(cachedStatuses);
      print('-----------------------------------------------');
      print('Статусы, которые были в кэше:');
      for (var status in decodedData) {
        print('ID: ${status['id']}, Название: ${status['name']}');
      }
    } else {
      print('Нет кэшированных статусов для удаления.');
    }

    // Удаляем кэшированные статусы
    await prefs.remove(_cachedTaskStatusesKey);

    // Очищаем кэш задач, связанные с этими статусами
    final Set<int> statusIds = decodedData.map<int>((status) => status['id']).toSet();
    for (var statusId in statusIds) {
      await prefs.remove('cachedTasks_$statusId');
      print('Удалены задачи для статуса с ID: $statusId');
    }

    // Выводим сообщение об удалении всех статусов и задач
    print('-----------------------------------------------');
    print('УДАЛЕНЫ ВСЕ СТАТУСЫ И ЗАДАЧИ ИЗ КЕША !!!');
  }

  // Очистить все кэшированные данные
  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedTaskStatusesKey);
  }
}

// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

// class TaskCache {
//   static const String _cachedTaskStatusesKey = 'cachedTaskStatuses';

//   // Save task statuses to cache
//   static Future<void> cacheTaskStatuses(List<Map<String, dynamic>> taskStatuses) async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     final String encodedStatuses = json.encode(taskStatuses);
//     await prefs.setString(_cachedTaskStatusesKey, encodedStatuses);
//   }

//   // Get task statuses from cache
//   static Future<List<Map<String, dynamic>>> getTaskStatuses() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     final String? cachedStatuses = prefs.getString(_cachedTaskStatusesKey);
    
//     if (cachedStatuses != null) {
//       final List<dynamic> decodedData = json.decode(cachedStatuses);
//       return decodedData.map((status) => Map<String, dynamic>.from(status)).toList();
//     }
//     return [];
//   }

//   // Clear the cached task statuses
//   static Future<void> clearCache() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_cachedTaskStatusesKey);
//   }
// }
