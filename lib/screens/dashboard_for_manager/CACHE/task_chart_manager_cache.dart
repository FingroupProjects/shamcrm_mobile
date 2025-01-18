import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TaskChartCacheHandlerManager {
  static const _cacheKey = 'task_chart_data_manager';

  // Сохранить данные графика задач в кэш
  static Future<void> saveTaskChartDataManager(List<double> data) async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = json.encode(data);
    await prefs.setString(_cacheKey, dataString);
  }

  // Получить данные графика задач из кэша
  static Future<List<double>?> getTaskChartDataManager() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_cacheKey);
    if (dataString != null) {
      final List<dynamic> jsonData = json.decode(dataString);

      return jsonData.map((e) {
        if (e is num) {
          return e.toDouble(); 
        } else {
          return double.tryParse(e.toString()) ?? 0.0; 
        }
      }).toList();
    }
    return null;
  }

  // Очистить кэш
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
