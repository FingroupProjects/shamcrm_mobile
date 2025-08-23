import 'dart:convert';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadCache {
  static const String _cachedLeadStatusesKey = 'cachedLeadStatuses';
  static const String _cachedLeadsKey = 'cachedLeads';

  static Future<void> cacheLeadsForStatus(int? statusId, List<Lead> leads) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedLeads_$statusId';
    final String encodedLeads = json.encode(leads.map((lead) => lead.toJson()).toList());
    await prefs.setString(key, encodedLeads);
    print('LeadCache: Cached leads for statusId: $statusId, count: ${leads.length}');
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

  static Future<void> moveLeadToStatus(Lead lead, int oldStatusId, int newStatusId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get leads from the old status
    final String oldKey = 'cachedLeads_$oldStatusId';
    final String? oldCachedLeads = prefs.getString(oldKey);
    List<Lead> oldLeads = [];
    if (oldCachedLeads != null) {
      final List<dynamic> decodedData = json.decode(oldCachedLeads);
      oldLeads = decodedData.map((lead) => Lead.fromJson(lead, oldStatusId)).toList();
    }

    // Remove the lead from the old status
    oldLeads.removeWhere((l) => l.id == lead.id);
    await prefs.setString(oldKey, json.encode(oldLeads.map((lead) => lead.toJson()).toList()));
    print('LeadCache: Removed lead ${lead.id} from status $oldStatusId, new count: ${oldLeads.length}');

    // Get leads from the new status
    final String newKey = 'cachedLeads_$newStatusId';
    final String? newCachedLeads = prefs.getString(newKey);
    List<Lead> newLeads = [];
    if (newCachedLeads != null) {
      final List<dynamic> decodedData = json.decode(newCachedLeads);
      newLeads = decodedData.map((lead) => Lead.fromJson(lead, newStatusId)).toList();
    }

    // Create a new Lead instance with updated statusId
    final updatedLead = Lead.fromJson(lead.toJson(), newStatusId);
    newLeads.add(updatedLead);
    await prefs.setString(newKey, json.encode(newLeads.map((lead) => lead.toJson()).toList()));
    print('LeadCache: Added lead ${lead.id} to status $newStatusId, new count: ${newLeads.length}');

    // Update lead counts
    await updateLeadCount(oldStatusId, oldLeads.length);
    await updateLeadCount(newStatusId, newLeads.length);
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
      statuses.add({'id': statusId, 'title': '', 'leads_count': count});
    }

    await prefs.setString(_cachedLeadStatusesKey, json.encode(statuses));
    print('LeadCache: Updated leads_count for statusId: $statusId to $count');
  }

  static Future<void> clearAllLeads() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final leadKeys = keys.where((key) => key.startsWith('cachedLeads_')).toList();

    for (var key in leadKeys) {
      await prefs.remove(key);
    }
    print('LeadCache: Cleared all leads');
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
    print('LeadCache: Cleared lead statuses and associated leads');
  }

  static Future<void> cacheLeadStatuses(List<LeadStatus> leadStatuses) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> statusesToCache = leadStatuses.map((status) => {
      'id': status.id,
      'title': status.title,
      'leads_count': status.leadsCount,
    }).toList();
    final String encodedStatuses = json.encode(statusesToCache);
    await prefs.setString(_cachedLeadStatusesKey, encodedStatuses);
    print('LeadCache: Cached statuses with leads_count: $statusesToCache');
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

  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedLeadStatusesKey);
    print('LeadCache: Cleared cache');
  }
}