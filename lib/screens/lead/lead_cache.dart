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
  static Future<void> cacheLeadsForStatus(int? statusId, List<Lead> leads) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedLeads_$statusId';
    final String encodedLeads = json.encode(leads.map((lead) => lead.toJson()).toList());
    await prefs.setString(key, encodedLeads);
  }

  // Get leads for a specific status from cache
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

  // Clear all cached leads
  static Future<void> clearAllLeads() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Get all the keys from SharedPreferences
    final keys = prefs.getKeys();

    // Filter out the keys that are related to leads
    final leadKeys = keys.where((key) => key.startsWith('cachedLeads_')).toList();
    
    // Remove all lead-related keys
    for (var key in leadKeys) {
      await prefs.remove(key);
      print('Удалены лиды для ключа: $key');
    }

    print('-----------------------------------------------');
    print('УДАЛЕНЫ ВСЕ ЛИДЫ ИЗ КЕША !!!');
  }

  // Clear cached lead statuses and leads
  static Future<void> clearLeadStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedLeadStatusesKey);

    List<dynamic> decodedData = [];

    if (cachedStatuses != null) {
      decodedData = json.decode(cachedStatuses);
      print('-----------------------------------------------');
      print('Статусы, которые были в кэше:');
      for (var status in decodedData) {
        print('ID: ${status['id']}, Название: ${status['name']}');
      }
    } else {
      print('Нет кэшированных статусов для удаления.');
    }

    // Удаляем кэшированные статусы
    await prefs.remove(_cachedLeadStatusesKey);

    // Очищаем кэш лидов, связанные с этими статусами
    final Set<int> statusIds = decodedData.map<int>((status) => status['id']).toSet();
    for (var statusId in statusIds) {
      await prefs.remove('cachedLeads_$statusId');
      print('Удалены лиды для статуса с ID: $statusId');
    }

    // Выводим сообщение об удалении всех статусов и лидов
    print('-----------------------------------------------');
    print('УДАЛЕНЫ ВСЕ СТАТУСЫ И ЛИДЫ ИЗ КЕША !!!');
  }

  // Clear the cached data
  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedLeadStatusesKey);
  }
}
