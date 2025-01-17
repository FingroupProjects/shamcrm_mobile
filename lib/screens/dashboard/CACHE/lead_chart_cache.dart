import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_chart_model.dart';

class LeadChartCacheHandler {
  static const _leadChartKey = 'leadChartData';

  static Future<void> saveLeadChartData(List<ChartData> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = json.encode(data.map((chart) => chart.toJson()).toList());
    await prefs.setString(_leadChartKey, jsonData);
  }

  static Future<List<ChartData>?> getLeadChartData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_leadChartKey);
    if (jsonData != null) {
      List<dynamic> decodedData = json.decode(jsonData);
      return decodedData.map((json) => ChartData.fromJson(json)).toList();
    }
    return null;
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_leadChartKey);
  }
}
