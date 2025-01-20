import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/deal_stats_model.dart';

class DealStatsCache {
  static const String _cacheKey = 'dealStatsCache';

  /// Сохранение данных в кеш
  static Future<void> saveDealStatsData(List<MonthData> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(data.map((e) => e.toJson()).toList());
    await prefs.setString(_cacheKey, jsonData);
  }

  /// Загрузка данных из кеша
  static Future<List<MonthData>?> getDealStatsData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_cacheKey);

    if (jsonData == null) {
      return null;
    }

    final List<dynamic> rawList = jsonDecode(jsonData);
    return rawList.map((e) => MonthData.fromJson(e)).toList();
  }
}
