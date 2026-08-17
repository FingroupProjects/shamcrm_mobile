import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/storage/secure_storage_service.dart';
import 'package:crm_task_manager/services/notification_cache.dart';
import 'package:crm_task_manager/offline/core/offline_runtime.dart';
import 'package:crm_task_manager/page_2/order/order_cache.dart';
import 'package:crm_task_manager/screens/deal/deal_cache.dart';
import 'package:crm_task_manager/screens/event/event_cache.dart';
import 'package:crm_task_manager/screens/lead/lead_cache.dart';
import 'package:crm_task_manager/screens/my-task/my_task_cache.dart';
import 'package:crm_task_manager/screens/sip/sip_service.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:crm_task_manager/services/chat_media_persistent_cache.dart';
import 'package:crm_task_manager/services/message_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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

    try {
      await SipService().clearSavedCredentials(
        revokeBackendVoipToken: notifyServer,
      );
    } catch (e) {
      debugPrint('AppLogoutService: SIP cleanup error: $e');
    }

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
        _runCleanup('deals', DealCache.clearEverything),
        _runCleanup('leads', LeadCache.clearEverything),
        _runCleanup('tasks', TaskCache.clearEverything),
        _runCleanup('events', EventCache.clearEverything),
        _runCleanup('my tasks', MyTaskCache.clearAllMyTasks),
        _runCleanup('my task cache', MyTaskCache.clearCache),
        _runCleanup('orders', OrderCache.clearAllData),
        _runCleanup('notifications', NotificationCacheHandler.clearCache),
        _runCleanup('chat messages', MessageCacheService().clearAllCache),
        _runCleanup(
          'chat media',
          ChatMediaPersistentCache.instance.clearAll,
        ),
        if (OfflineRuntime.isInitialized)
          _runCleanup(
            'offline database',
            OfflineRuntime.instance.database.clearAllData,
          ),
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
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      await _clearDownloadedFileCache();
      await _clearTemporaryFiles();
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

  static Future<void> _runCleanup(
    String label,
    Future<void> Function() cleanup,
  ) async {
    try {
      await cleanup();
    } catch (error) {
      debugPrint('AppLogoutService: $label cleanup error: $error');
    }
  }

  static Future<void> _clearTemporaryFiles() async {
    try {
      final directory = await getTemporaryDirectory();
      if (!await directory.exists()) return;

      for (final entity in directory.listSync()) {
        try {
          if (entity is Directory) {
            await entity.delete(recursive: true);
          } else if (entity is File) {
            await entity.delete();
          }
        } catch (error) {
          debugPrint(
            'AppLogoutService: temporary item cleanup error '
            '(${entity.path}): $error',
          );
        }
      }
    } catch (error) {
      debugPrint('AppLogoutService: temporary directory cleanup error: $error');
    }
  }

  static Future<void> _clearDownloadedFileCache() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final cachedFilesDirectory =
          Directory('${documentsDirectory.path}/cached_files');
      if (await cachedFilesDirectory.exists()) {
        await cachedFilesDirectory.delete(recursive: true);
      }
    } catch (error) {
      debugPrint('AppLogoutService: downloaded files cleanup error: $error');
    }
  }
}
