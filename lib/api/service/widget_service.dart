import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WidgetService {
  static const platform = MethodChannel('com.softtech.crm_task_manager/widget');
  
  // Callback для навигации
  static Function(int group, int screenIndex)? onNavigateFromWidget;
  
  // Инициализация слушателя
  static void initialize() {
    platform.setMethodCallHandler(_handleMethodCall);
    debugPrint('WidgetService initialized');
  }
  
  static Future<void> _handleMethodCall(MethodCall call) async {
    debugPrint('WidgetService: Received method call: ${call.method}');
    
    if (call.method == 'navigateFromWidget') {
      final int group = call.arguments['group'];
      final int screenIndex = call.arguments['screenIndex'];
      
      debugPrint('WidgetService: Navigate to group=$group, screen=$screenIndex');
      
      // Вызываем callback для навигации
      onNavigateFromWidget?.call(group, screenIndex);
    }
  }
}