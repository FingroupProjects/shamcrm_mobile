import 'dart:convert';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadCache {
  static const String _cachedLeadStatusesKey = 'cachedLeadStatuses';
  static const String _cachedLeadsKey = 'cachedLeads';

  // Save lead statuses to cache
  static Future<void> cacheLeadStatuses(List<Map<String, dynamic>> leadStatuses) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedStatuses = json.encode(leadStatuses);
    await prefs.setString(_cachedLeadStatusesKey, encodedStatuses);
  }

  // Get lead statuses from cache
  static Future<List<Map<String, dynamic>>> getLeadStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedLeadStatusesKey);
    
    if (cachedStatuses != null) {
      final List<dynamic> decodedData = json.decode(cachedStatuses);
      return decodedData.map((status) => Map<String, dynamic>.from(status)).toList();
    }
    return [];
  }

  // Save leads for a specific status to cache
// Метод для кэширования лидов по статусам
static Future<void> cacheLeadsForStatus(int? statusId, List<Lead> leads) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String key = 'cachedLeads_$statusId';
  final String encodedLeads = json.encode(leads.map((lead) => lead.toJson()).toList());
  await prefs.setString(key, encodedLeads);
}

// Метод для получения лидов из кэша по статусу
static Future<List<Lead>> getLeadsForStatus(int? statusId) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String key = 'cachedLeads_$statusId';
  final String? cachedLeads = prefs.getString(key);

  if (cachedLeads != null) {
    final List<dynamic> decodedData = json.decode(cachedLeads);
    return decodedData.map((lead) => Lead.fromJson(lead, statusId ?? 0)).toList();
  }
  return [];
}



  // Clear the cached data
  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedLeadStatusesKey);
    await prefs.clear();
  }
}
