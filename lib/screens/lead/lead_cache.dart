import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LeadCache {
  static const String _cachedLeadStatusesKey = 'cachedLeadStatuses';

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

  // Clear the cached lead statuses
  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedLeadStatusesKey);
  }
}
