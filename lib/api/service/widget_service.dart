import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WidgetService {
  static const platform = MethodChannel('com.softtech.crm_task_manager/widget');

  // Callback для навигации (Android формат: group + screenIndex)
  static Function(int group, int screenIndex)? onNavigateFromWidget;
  
  // Callback для навигации (iOS формат: screen identifier)
  static Function(String screenIdentifier)? onNavigateFromWidgetByScreen;

  // Инициализация слушателя
  static void initialize() {
    platform.setMethodCallHandler(_handleMethodCall);
    debugPrint('WidgetService initialized');
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    debugPrint('WidgetService: Received method call: ${call.method}');
    debugPrint('WidgetService: Arguments: ${call.arguments}');

    if (call.method == 'navigateFromWidget') {
      final args = call.arguments as Map<dynamic, dynamic>?;
      
      if (args == null) {
        debugPrint('WidgetService: No arguments provided');
        return;
      }

      // Android формат: {group: 1, screenIndex: 0}
      if (args.containsKey('group') && args.containsKey('screenIndex')) {
        final int group = args['group'] as int;
        final int screenIndex = args['screenIndex'] as int;

        debugPrint('WidgetService: Android format - Navigate to group=$group, screen=$screenIndex');

        // Вызываем callback для навигации (Android)
        onNavigateFromWidget?.call(group, screenIndex);
      }
      // iOS формат: {screen: "dashboard"}
      else if (args.containsKey('screen')) {
        final String screenIdentifier = args['screen'] as String;

        debugPrint('WidgetService: iOS format - Navigate to screen=$screenIdentifier');

        // Вызываем callback для навигации (iOS)
        onNavigateFromWidgetByScreen?.call(screenIdentifier);
      } else {
        debugPrint('WidgetService: Unknown format - arguments: $args');
      }
    }
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
}