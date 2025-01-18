import 'dart:convert';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/lead_chart_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadChartCacheHandlerManager {
  static const _leadChartKey = 'leadChartDataManager';

  static Future<void> saveLeadChartDataManager(List<ChartDataManager> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = json.encode(data.map((chart) => chart.toJson()).toList());
    await prefs.setString(_leadChartKey, jsonData);
  }

  static Future<List<ChartDataManager>?> getLeadChartDataManager() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_leadChartKey);
    if (jsonData != null) {
      List<dynamic> decodedData = json.decode(jsonData);
      return decodedData.map((json) => ChartDataManager.fromJson(json)).toList();
    }
    return null;
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_leadChartKey);
  }
}
