import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TaskChartCacheHandler {
  static const _cacheKey = 'task_chart_data';

  // Сохранить данные графика задач в кэш
  static Future<void> saveTaskChartData(List<double> data) async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = json.encode(data);
    await prefs.setString(_cacheKey, dataString);
  }

  // Получить данные графика задач из кэша
  static Future<List<double>?> getTaskChartData() async {
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

// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

// class TaskChartCacheHandler {
//   static const String _cacheKey = 'task_chart_data';

//   // Save data to cache
//   static Future<void> saveTaskChartData(List<double> data) async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonData = json.encode(data); // Encode data as JSON
//     await prefs.setString(_cacheKey, jsonData);
//   }

//   // Retrieve data from cache
//   static Future<List<double>?> getTaskChartData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonData = prefs.getString(_cacheKey);

//     if (jsonData != null) {
//       final List<dynamic> decodedData = json.decode(jsonData);
//       return decodedData.map((x) => (x as num).toDouble()).toList();
//     }
//     return null;
//   }

//   // Clear cache
//   static Future<void> clearCache() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_cacheKey);
//   }
// }




