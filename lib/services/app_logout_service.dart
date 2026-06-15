import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/secure_storage_service.dart';
import 'package:crm_task_manager/notification_cache.dart';
import 'package:crm_task_manager/page_2/order/order_cache.dart';
import 'package:crm_task_manager/screens/deal/deal_cache.dart';
import 'package:crm_task_manager/screens/event/event_cache.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:crm_task_manager/screens/my-task/my_task_cache.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:crm_task_manager/services/message_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLogoutService {
  static const Set<String> _appearanceKeys = <String>{
    'app_theme_mode_v1',
    'app_palette_preset_v1',
    'app_background_preset_v1',
    'app_background_image_path_v1',
    'app_background_asset_path_v1',
    'app_background_blur_v1',
    'app_palette_seed_color_v1',
  };

  static Future<void> logoutAndReset({
    BuildContext? context,
    bool restartApp = true,
    bool navigateToAuth = true,
    bool notifyServer = true,
  }) async {
    final apiService = ApiService();
    final authService = AuthService();

    if (notifyServer) {
      try {
        await apiService.logoutAccount();
      } catch (e) {
        debugPrint('AppLogoutService: logoutAccount error: $e');
      }
    }

    try {
      await apiService.logout();
      await apiService.reset();
      await authService.clearAllAuthData();

      await Future.wait([
        DealCache.clearEverything(),
        LeadCache.clearEverything(),
        TaskCache.clearEverything(),
        EventCache.clearEverything(),
        MyTaskCache.clearAllMyTasks(),
        MyTaskCache.clearCache(),
        OrderCache.clearAllData(),
        NotificationCacheHandler.clearCache(),
        MessageCacheService().clearAllCache(),
      ]);

      ApiService.clearAnalyticsResponseCache();

      final prefs = await SharedPreferences.getInstance();
      final preservedAppearanceValues = <String, Object?>{
        for (final key in prefs.getKeys().where(_appearanceKeys.contains))
          key: prefs.get(key),
      };
      await prefs.clear();
      for (final entry in preservedAppearanceValues.entries) {
        // SharedPreferences.clear() removes everything, so restore appearance
        // settings afterwards to keep the selected background stable.
        final key = entry.key;
        final value = entry.value;
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }
      }
    } catch (e) {
      debugPrint('AppLogoutService: local cleanup error: $e');
    }

    if (restartApp) {
      Restart.restartApp();
      return;
    }

    if (!navigateToAuth || context == null || !context.mounted) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      '/local_auth',
      (route) => false,
    );
  }
}
