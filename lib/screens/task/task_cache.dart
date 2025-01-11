import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TaskCache {
  static const String _cachedTaskStatusesKey = 'cachedTaskStatuses';

  // Save task statuses to cache
  static Future<void> cacheTaskStatuses(List<Map<String, dynamic>> taskStatuses) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedStatuses = json.encode(taskStatuses);
    await prefs.setString(_cachedTaskStatusesKey, encodedStatuses);
  }

  // Get task statuses from cache
  static Future<List<Map<String, dynamic>>> getTaskStatuses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedStatuses = prefs.getString(_cachedTaskStatusesKey);
    
    if (cachedStatuses != null) {
      final List<dynamic> decodedData = json.decode(cachedStatuses);
      return decodedData.map((status) => Map<String, dynamic>.from(status)).toList();
    }
    return [];
  }

  // Clear the cached task statuses
  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedTaskStatusesKey);
  }
}
