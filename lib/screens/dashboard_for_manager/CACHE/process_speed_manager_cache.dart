import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProcessSpeedCacheManager {
  static const _cacheKey = 'process_speed_data_manager';

  static Future<void> saveProcessSpeedDataManager(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, json.encode({'speed': speed}));
  }

  static Future<double?> getProcessSpeedDataManager() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_cacheKey);
    if (data != null) {
      final Map<String, dynamic> jsonData = json.decode(data);
      return (jsonData['speed'] as num?)?.toDouble();
    }
    return null;
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
