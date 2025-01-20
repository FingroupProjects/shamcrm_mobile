import 'dart:convert';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/deal_stats_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DealStatsCacheManager {
  static const String _cacheKey = 'dealStatsCacheManager';

  /// Сохранение данных в кеш
  static Future<void> saveDealStatsDataManager(List<MonthData> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(data.map((e) => e.toJson()).toList());
    await prefs.setString(_cacheKey, jsonData);
  }

  /// Загрузка данных из кеша
  static Future<List<MonthData>?> getDealStatsDataManager() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_cacheKey);

    if (jsonData == null) {
      return null;
    }

    final List<dynamic> rawList = jsonDecode(jsonData);
    return rawList.map((e) => MonthData.fromJson(e)).toList();
  }
}
