import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/models/notifications_model.dart';

class NotificationCacheHandler {
  static const _cacheKey = 'notifications_cache';

  // Сохранение уведомлений в кэш
  static Future<void> saveNotifications(
      List<Notifications> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        json.encode(notifications.map((e) => e.toJson()).toList());
    await prefs.setString(_cacheKey, jsonString);
  }

  // Получение уведомлений из кэша
  static Future<List<Notifications>?> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    if (jsonString == null) return null;

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((e) {
            try {
              return Notifications.fromJson(e);
            } catch (e) {
              //print('Ошибка десериализации кэшированного уведомления: $e, JSON: $e');
              return null;
            }
          })
          .where((e) => e != null)
          .cast<Notifications>()
          .toList();
    } catch (e) {
      //print('Ошибка декодирования кэша: $e');
      return null;
    }
  }

  // Очистка кэша уведомлений
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
