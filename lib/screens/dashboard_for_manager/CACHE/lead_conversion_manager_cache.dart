import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHandlerManager {
  static const _leadConversionKey = 'leadConversionDataManager';

  // Save data to cache
  static Future<void> saveLeadConversionDataManager(List<double> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = json.encode(data);
    await prefs.setString(_leadConversionKey, jsonData);
  }

  // Retrieve data from cache
  static Future<List<double>?> getLeadConversionDataManager() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_leadConversionKey);
    if (jsonData != null) {
      List<dynamic> decodedData = json.decode(jsonData);
      return decodedData.map((e) => (e as num).toDouble()).toList();
    }
    return null;
  }

  // Clear cache data
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_leadConversionKey);
  }
}
