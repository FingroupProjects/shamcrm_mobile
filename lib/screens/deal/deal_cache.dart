import 'dart:convert';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DealCache {
  static const String _cachedDealStatusesKey = 'cachedDealStatuses';
  static const String _cachedDealsKey = 'cachedDeals';

  // Save deal statuses to cache
  static Future<void> cacheDealStatuses(List<Map<String, dynamic>> dealStatuses) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedStatuses = json.encode(dealStatuses);
    await prefs.setString(_cachedDealStatusesKey, encodedStatuses);
  }

  // Get deal statuses from cache
  static Future<List<Map<String, dynamic>>> getDealStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedDealStatusesKey);

    if (cachedStatuses != null) {
      final List<dynamic> decodedData = json.decode(cachedStatuses);
      return decodedData.map((status) => Map<String, dynamic>.from(status)).toList();
    }
    return [];
  }

  // Save deals for a specific status to cache
  static Future<void> cacheDealsForStatus(int? statusId, List<Deal> deals) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedDeals_$statusId';
    final String encodedDeals = json.encode(deals.map((deal) => deal.toJson()).toList());
    await prefs.setString(key, encodedDeals);
  }

  // Get deals for a specific status from cache
  static Future<List<Deal>> getDealsForStatus(int? statusId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedDeals_$statusId';
    final String? cachedDeals = prefs.getString(key);

    if (cachedDeals != null) {
      final List<dynamic> decodedData = json.decode(cachedDeals);
      return decodedData.map((deal) => Deal.fromJson(deal, statusId ?? 0)).toList();
    }
    return [];
  }

  // Clear all cached deals
  static Future<void> clearAllDeals() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get all the keys from SharedPreferences
    final keys = prefs.getKeys();

    // Filter out the keys that are related to deals
    final dealKeys = keys.where((key) => key.startsWith('cachedDeals_')).toList();

    // Remove all deal-related keys
    for (var key in dealKeys) {
      await prefs.remove(key);
    }

  }

  // Clear cached deal statuses and deals
  static Future<void> clearDealStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedDealStatusesKey);

    List<dynamic> decodedData = [];

    if (cachedStatuses != null) {
      decodedData = json.decode(cachedStatuses);
    }

    // Удаляем кэшированные статусы сделок
    await prefs.remove(_cachedDealStatusesKey);

    // Очищаем кэш сделок, связанные с этими статусами
    final Set<int> statusIds = decodedData.map<int>((status) => status['id']).toSet();
    for (var statusId in statusIds) {
      await prefs.remove('cachedDeals_$statusId');
    }
  }

  // Clear the cached data
  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedDealStatusesKey);
  }
}
