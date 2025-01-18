import 'dart:convert';
import 'package:crm_task_manager/models/dashboard_charts_models/user_task%20_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskCompletionCache {
  static const String _cacheKey = 'user_task_completion_data';

  // Сохранение данных в кеш
  static Future<void> saveTaskCompletionData(List<UserTaskCompletion> data) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonData = data.map((task) => json.encode(task.toJson())).toList();
    await prefs.setStringList(_cacheKey, jsonData);
  }

  // Извлечение данных из кеша
  static Future<List<UserTaskCompletion>?> getTaskCompletionData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getStringList(_cacheKey);

    if (cachedData != null) {
      return cachedData.map((item) => UserTaskCompletion.fromJson(json.decode(item))).toList();
    }
    return null;
  }
}
