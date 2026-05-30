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
      await prefs.clear();
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
