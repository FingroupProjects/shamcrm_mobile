import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WidgetService {
  static const platform = MethodChannel('com.softtech.crm_task_manager/widget');
  
  // Callback для навигации с screen identifier
  static Function(String screenIdentifier)? onNavigateFromWidget;
  
  // Инициализация слушателя
  static void initialize() {
    platform.setMethodCallHandler(_handleMethodCall);
    debugPrint('WidgetService initialized');
  }
  
  static Future<void> _handleMethodCall(MethodCall call) async {
    debugPrint('WidgetService: Received method call: ${call.method}');
    
    if (call.method == 'navigateFromWidget') {
      final String? screenIdentifier = call.arguments['screen'] as String?;
      
      if (screenIdentifier != null) {
        debugPrint('WidgetService: Navigate to screen=$screenIdentifier');
        
        // Вызываем callback для навигации с screen identifier
        onNavigateFromWidget?.call(screenIdentifier);
      } else {
        debugPrint('WidgetService: Missing screen identifier');
      }
    }
  }
}