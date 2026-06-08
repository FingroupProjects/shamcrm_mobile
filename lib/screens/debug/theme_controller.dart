import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/core/theme/palette/dark_palette.dart';
import 'package:crm_task_manager/core/theme/palette/light_palette.dart';

/// Контроллер темы приложения
class ThemeController extends ChangeNotifier {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal() {
    AppThemeController.instance.addListener(notifyListeners);
  }

  bool get isDarkMode => AppThemeController.instance.isDarkMode;

  void toggleTheme() {
    AppThemeController.instance.toggleTheme();
  }

  void setTheme(bool isDark) {
    AppThemeController.instance
        .setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}

/// Светлая тема
class LightThemeColors {
  static const background = LightPalette.neutral100;
  static const surface = LightPalette.neutral0;
  static const surfaceVariant = LightPalette.neutral200;
  static const primary = LightPalette.brandAccent;
  static const onSurface = LightPalette.brandPrimaryDark;
  static const onSurfaceVariant = LightPalette.neutral500;
  static const border = LightPalette.neutral300;
  static const success = LightPalette.success;
  static const warning = LightPalette.warning;
  static const error = LightPalette.error;
}

/// Тёмная тема
class DarkThemeColors {
  static const background = DarkPalette.neutral50;
  static const surface = DarkPalette.neutral200;
  static const surfaceVariant = DarkPalette.neutral300;
  static const primary = DarkPalette.brandAccent;
  static const onSurface = DarkPalette.neutral900;
  static const onSurfaceVariant = DarkPalette.neutral600;
  static const border = DarkPalette.neutral400;
  static const success = DarkPalette.success;
  static const warning = DarkPalette.warning;
  static const error = DarkPalette.error;
}
