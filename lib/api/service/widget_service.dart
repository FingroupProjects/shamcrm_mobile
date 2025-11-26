import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetService {
  static const platform = MethodChannel('com.softtech.crm_task_manager/widget');

  // Callback для навигации (Android формат: group + screenIndex) - legacy
  static Function(int group, int screenIndex)? onNavigateFromWidget;
  
  // Callback для навигации (screen identifier format - used by both iOS and Android)
  static Function(String screenIdentifier)? onNavigateFromWidgetByScreen;
  
  // Pending navigation when callback isn't set yet (app cold start)
  static String? _pendingScreenNavigation;

  // Инициализация слушателя
  static void initialize() {
    debugPrint('WidgetService: === initialize() called ===');
    platform.setMethodCallHandler(_handleMethodCall);
    debugPrint('WidgetService: MethodCallHandler set');
    
    // Check for pending navigation from Android (cold start scenario)
    _checkAndroidPendingNavigation();
  }
  
  /// Check if Android has pending navigation stored (for cold start)
  static Future<void> _checkAndroidPendingNavigation() async {
    debugPrint('WidgetService: === _checkAndroidPendingNavigation() ===');
    debugPrint('WidgetService: Platform.isAndroid = ${Platform.isAndroid}');
    
    if (!Platform.isAndroid) {
      debugPrint('WidgetService: Not Android, skipping');
      return;
    }
    
    try {
      debugPrint('WidgetService: Calling getPendingNavigation on native...');
      final pendingScreen = await platform.invokeMethod<String>('getPendingNavigation');
      debugPrint('WidgetService: Native returned: "$pendingScreen"');
      
      if (pendingScreen != null && pendingScreen.isNotEmpty) {
        debugPrint('WidgetService: Storing pending navigation: $pendingScreen');
        _pendingScreenNavigation = pendingScreen;
      } else {
        debugPrint('WidgetService: No pending navigation from native');
      }
    } catch (e) {
      debugPrint('WidgetService: Error checking pending navigation: $e');
    }
    
    debugPrint('WidgetService: _pendingScreenNavigation = $_pendingScreenNavigation');
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    debugPrint('WidgetService: === _handleMethodCall ===');
    debugPrint('WidgetService: Method: ${call.method}');
    debugPrint('WidgetService: Arguments: ${call.arguments}');
    debugPrint('WidgetService: onNavigateFromWidgetByScreen is null: ${onNavigateFromWidgetByScreen == null}');

    if (call.method == 'navigateFromWidget') {
      final args = call.arguments as Map<dynamic, dynamic>?;
      
      if (args == null) {
        debugPrint('WidgetService: No arguments provided');
        return;
      }

      // Legacy Android format: {group: 1, screenIndex: 0}
      if (args.containsKey('group') && args.containsKey('screenIndex')) {
        final int group = args['group'] as int;
        final int screenIndex = args['screenIndex'] as int;

        debugPrint('WidgetService: Legacy format - Navigate to group=$group, screen=$screenIndex');
        debugPrint('WidgetService: onNavigateFromWidget is null: ${onNavigateFromWidget == null}');

        // Вызываем callback для навигации (legacy)
        onNavigateFromWidget?.call(group, screenIndex);
      }
      // Screen identifier format: {screen: "dashboard"} - used by both iOS and Android
      else if (args.containsKey('screen')) {
        final String screenIdentifier = args['screen'] as String;

        debugPrint('WidgetService: Screen format - Navigate to screen=$screenIdentifier');

        // If callback is set, call it immediately
        if (onNavigateFromWidgetByScreen != null) {
          debugPrint('WidgetService: Callback exists, calling now');
          onNavigateFromWidgetByScreen!(screenIdentifier);
        } else {
          // Store for later when HomeScreen is ready
          debugPrint('WidgetService: Callback is NULL, storing for later');
          _pendingScreenNavigation = screenIdentifier;
          debugPrint('WidgetService: Stored pending navigation: $screenIdentifier');
        }
      } else {
        debugPrint('WidgetService: Unknown format - arguments: $args');
      }
    }
  }
  
  /// Check and consume pending navigation (called by HomeScreen when ready)
  static String? consumePendingNavigation() {
    debugPrint('WidgetService: === consumePendingNavigation() called ===');
    debugPrint('WidgetService: Current _pendingScreenNavigation = $_pendingScreenNavigation');
    
    final pending = _pendingScreenNavigation;
    _pendingScreenNavigation = null;
    
    if (pending != null) {
      debugPrint('WidgetService: Consuming and returning: $pending');
    } else {
      debugPrint('WidgetService: No pending navigation to consume');
    }
    return pending;
  }

  /// Sync permissions to iOS widget via App Groups
  /// This allows the widget to show/hide icons based on user permissions
  static Future<void> syncPermissionsToWidget(List<String> permissions) async {
    // Only sync on iOS
    if (!Platform.isIOS) {
      debugPrint('WidgetService: Skipping permission sync (not iOS)');
      return;
    }

    try {
      final result = await platform.invokeMethod('syncPermissionsToWidget', {
        'permissions': permissions,
      });
      debugPrint('WidgetService: Synced ${permissions.length} permissions to widget: $result');
    } on PlatformException catch (e) {
      debugPrint('WidgetService: Failed to sync permissions to widget: ${e.message}');
    } catch (e) {
      debugPrint('WidgetService: Error syncing permissions: $e');
    }
  }

  /// Sync language to iOS widget via App Groups
  /// This allows the widget to display labels in the correct language
  static Future<void> syncLanguageToWidget(String languageCode) async {
    // Only sync on iOS
    if (!Platform.isIOS) {
      debugPrint('WidgetService: Skipping language sync (not iOS)');
      return;
    }

    try {
      final result = await platform.invokeMethod('syncLanguageToWidget', {
        'languageCode': languageCode,
      });
      debugPrint('WidgetService: Synced language to widget: $languageCode, result: $result');
    } on PlatformException catch (e) {
      debugPrint('WidgetService: Failed to sync language to widget: ${e.message}');
    } catch (e) {
      debugPrint('WidgetService: Error syncing language: $e');
    }
  }

  /// Sync widget visibility flags to Android SharedPreferences
  /// This allows the Android widget to show/hide buttons based on permissions
  static Future<void> syncWidgetVisibilityToAndroid(Map<String, bool> visibility) async {
    // Only sync on Android
    if (!Platform.isAndroid) {
      debugPrint('WidgetService: Skipping Android widget sync (not Android)');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save visibility flags with widget_ prefix
      for (final entry in visibility.entries) {
        await prefs.setBool('widget_show_${entry.key}', entry.value);
      }
      
      debugPrint('WidgetService: Synced visibility to Android widget: $visibility');
      
      // Trigger widget update after saving
      await triggerAndroidWidgetUpdate();
    } catch (e) {
      debugPrint('WidgetService: Error syncing Android widget visibility: $e');
    }
  }

  /// Trigger Android widget update via MethodChannel
  static Future<void> triggerAndroidWidgetUpdate() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await platform.invokeMethod('updateWidget');
      debugPrint('WidgetService: Triggered Android widget update');
    } on PlatformException catch (e) {
      debugPrint('WidgetService: Failed to trigger widget update: ${e.message}');
    } catch (e) {
      debugPrint('WidgetService: Error triggering widget update: $e');
    }
  }

  /// Clear Android widget visibility flags (e.g., on logout)
  static Future<void> clearAndroidWidgetVisibility() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all widget visibility flags
      final keys = ['dashboard', 'tasks', 'leads', 'deals', 'chats'];
      for (final key in keys) {
        await prefs.remove('widget_show_$key');
      }
      
      debugPrint('WidgetService: Cleared Android widget visibility');
      await triggerAndroidWidgetUpdate();
    } catch (e) {
      debugPrint('WidgetService: Error clearing Android widget visibility: $e');
    }
  }
}