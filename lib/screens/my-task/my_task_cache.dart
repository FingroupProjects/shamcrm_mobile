import 'dart:convert';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyTaskCache {
  static const String _cachedMyTaskStatusesKey = 'cachedMyTaskStatuses';
  static const String _cachedMyTasksKey = 'cachedMyTasks';

  // Сохранить статусы задач в кэш
  static Future<void> cacheMyTaskStatuses(List<Map<String, dynamic>> taskStatuses) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedStatuses = json.encode(taskStatuses);
    await prefs.setString(_cachedMyTaskStatusesKey, encodedStatuses);
  }

  // Получить статусы задач из кэша
  static Future<List<Map<String, dynamic>>> getMyTaskStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedMyTaskStatusesKey);
    
    if (cachedStatuses != null) {
      final List<dynamic> decodedData = json.decode(cachedStatuses);
      return decodedData.map((status) => Map<String, dynamic>.from(status)).toList();
    }
    return [];
  }

  // Сохранить задачи для определенного статуса в кэш
  static Future<void> cacheMyTasksForStatus(int? statusId, List<MyTask> tasks) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedMyTasks_$statusId';
    final String encodedMyTasks = json.encode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString(key, encodedMyTasks);
  }

  // Получить задачи для определенного статуса из кэша
  static Future<List<MyTask>> getMyTasksForStatus(int? statusId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedMyTasks_$statusId';
    final String? cachedMyTasks = prefs.getString(key);

    if (cachedMyTasks != null) {
      final List<dynamic> decodedData = json.decode(cachedMyTasks);
      return decodedData.map((task) => MyTask.fromJson(task, statusId ?? 0)).toList();
    }
    return [];
  }

  // Очистить все кэшированные задачи
  static Future<void> clearAllMyTasks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Получаем все ключи из SharedPreferences
    final keys = prefs.getKeys();

    // Фильтруем только те ключи, которые связаны с задачами
    final taskKeys = keys.where((key) => key.startsWith('cachedMyTasks_')).toList();
    
    // Удаляем все ключи, связанные с задачами
    for (var key in taskKeys) {
      await prefs.remove(key);
      print('Удалены задачи для ключа: $key');
    }

    print('-----------------------------------------------');
    print('УДАЛЕНЫ ВСЕ ЗАДАЧИ ИЗ КЕША !!!');
  }

  // Очистить кэшированные статусы задач и задачи
  static Future<void> clearMyTaskStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedMyTaskStatusesKey);

    List<dynamic> decodedData = [];

    if (cachedStatuses != null) {
      decodedData = json.decode(cachedStatuses);
      for (var status in decodedData) {
      }
    } else {
    }

    // Удаляем кэшированные статусы
    await prefs.remove(_cachedMyTaskStatusesKey);

    // Очищаем кэш задач, связанные с этими статусами
    final Set<int> statusIds = decodedData.map<int>((status) => status['id']).toSet();
    for (var statusId in statusIds) {
      await prefs.remove('cachedMyTasks_$statusId');
    }

    // Выводим сообщение об удалении всех статусов и задач
    print('-----------------------------------------------');
    print('УДАЛЕНЫ ВСЕ СТАТУСЫ И ЗАДАЧИ ИЗ КЕША !!!');
  }

  // Очистить все кэшированные данные
  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedMyTaskStatusesKey);
  }
}