import 'dart:convert';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadCache {
  static const String _cachedLeadStatusesKey = 'cachedLeadStatuses';
  static const String _cachedLeadsKey = 'cachedLeads';

  static Future<void> cacheLeadStatuses(List<Map<String, dynamic>> leadStatuses) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedStatuses = json.encode(leadStatuses);
    await prefs.setString(_cachedLeadStatusesKey, encodedStatuses);
  }

  static Future<List<Map<String, dynamic>>> getLeadStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedLeadStatusesKey);
    
    if (cachedStatuses != null) {
      final List<dynamic> decodedData = json.decode(cachedStatuses);
      return decodedData.map((status) => Map<String, dynamic>.from(status)).toList();
    }
    return [];
  }

  static Future<void> cacheLeadsForStatus(int? statusId, List<Lead> leads) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedLeads_$statusId';
    final String encodedLeads = json.encode(leads.map((lead) => lead.toJson()).toList());
    await prefs.setString(key, encodedLeads);
  }

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

  static Future<void> clearAllLeads() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final keys = prefs.getKeys();

    final leadKeys = keys.where((key) => key.startsWith('cachedLeads_')).toList();
    
    for (var key in leadKeys) {
      await prefs.remove(key);
    }
    print('CACHE LEADS CLEARED');

  }
 static Future<void> clearLeadsForStatus(int? statusId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedLeads_$statusId';
    await prefs.remove(key);
    print('LeadCache: Cleared leads for statusId: $statusId');
  }
  static Future<void> clearLeadStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedLeadStatusesKey);

    List<dynamic> decodedData = [];

    if (cachedStatuses != null) {
      decodedData = json.decode(cachedStatuses);
    }

    await prefs.remove(_cachedLeadStatusesKey);

    final Set<int> statusIds = decodedData.map<int>((status) => status['id']).toSet();
    for (var statusId in statusIds) {
      await prefs.remove('cachedLeads_$statusId');
    }

  }

static Future<void> updateLeadCount(int statusId, int count) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedLeadStatusesKey);
    List<Map<String, dynamic>> statuses = [];

    if (cachedStatuses != null) {
      statuses = (json.decode(cachedStatuses) as List<dynamic>)
          .map((status) => Map<String, dynamic>.from(status))
          .toList();
    }

    final index = statuses.indexWhere((status) => status['id'] == statusId);
    if (index != -1) {
      statuses[index]['leads_count'] = count;
    } else {
      statuses.add({'id': statusId, 'leads_count': count});
    }

    await prefs.setString(_cachedLeadStatusesKey, json.encode(statuses));
    print('LeadCache: Updated leads_count for statusId: $statusId to $count');
  }

  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedLeadStatusesKey);
  }
}
