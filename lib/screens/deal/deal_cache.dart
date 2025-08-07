import 'dart:convert';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DealCache {
  static const String _cachedDealStatusesKey = 'cachedDealStatuses';
  static const String _cachedDealsKey = 'cachedDeals';

  // Save deal statuses to cache, including deals_count
  static Future<void> cacheDealStatuses(List<Map<String, dynamic>> dealStatuses) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedStatuses = json.encode(dealStatuses);
    await prefs.setString(_cachedDealStatusesKey, encodedStatuses);
    print('DealCache: Cached deal statuses: $dealStatuses');
  }

  static Future<void> clearDealsForStatus(int? statusId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedDeals_$statusId';
    await prefs.remove(key);
    await prefs.remove('cacheTimestamp_$statusId');
    print('DealCache: Cleared deals for statusId: $statusId');
  }

  // Get deal statuses from cache
  static Future<List<Map<String, dynamic>>> getDealStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedDealStatusesKey);

    if (cachedStatuses != null) {
      final List<dynamic> decodedData = json.decode(cachedStatuses);
      final statuses = decodedData.map((status) => Map<String, dynamic>.from(status)).toList();
      print('DealCache: Retrieved deal statuses from cache: $statuses');
      return statuses;
    }
    print('DealCache: No cached deal statuses found');
    return [];
  }

  // Save deals for a specific status to cache
  static Future<void> cacheDealsForStatus(int? statusId, List<Deal> deals) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedDeals_$statusId';
    final String encodedDeals = json.encode(deals.map((deal) => deal.toJson()).toList());
    await prefs.setString(key, encodedDeals);
    print('DealCache: Cached deals for statusId: $statusId, count: ${deals.length}');
  }

  // Get deals for a specific status from cache
  static Future<List<Deal>> getDealsForStatus(int? statusId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = 'cachedDeals_$statusId';
    final String? cachedDeals = prefs.getString(key);

    if (cachedDeals != null) {
      final List<dynamic> decodedData = json.decode(cachedDeals);
      final deals = decodedData.map((deal) => Deal.fromJson(deal, statusId ?? 0)).toList();
      print('DealCache: Retrieved deals for statusId: $statusId, count: ${deals.length}');
      return deals;
    }
    print('DealCache: No cached deals found for statusId: $statusId');
    return [];
  }

  // Clear all cached deals
  static Future<void> clearAllDeals() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final dealKeys = keys.where((key) => key.startsWith('cachedDeals_')).toList();
    for (var key in dealKeys) {
      await prefs.remove(key);
      print('DealCache: Cleared cache for key: $key');
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

    await prefs.remove(_cachedDealStatusesKey);
    print('DealCache: Cleared deal statuses cache');

    final Set<int> statusIds = decodedData.map<int>((status) => status['id']).toSet();
    for (var statusId in statusIds) {
      await prefs.remove('cachedDeals_$statusId');
      print('DealCache: Cleared deals cache for statusId: $statusId');
    }
  }

  // Clear the cached data
  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedDealStatusesKey);
    print('DealCache: Cleared all cache');
  }
}