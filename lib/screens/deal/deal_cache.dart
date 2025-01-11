import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DealCache {
  static const String _cachedDealStatusesKey = 'cachedDealStatuses';

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

  // Clear the cached deal statuses
  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedDealStatusesKey);
  }
}
