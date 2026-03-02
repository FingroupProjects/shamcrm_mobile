import 'package:flutter/material.dart';

/// Контроллер темы приложения
class ThemeController extends ChangeNotifier {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal()
      : _isDarkMode = WidgetsBinding
                .instance.platformDispatcher.platformBrightness ==
            Brightness.dark;

  bool _isDarkMode;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}

/// Светлая тема
class LightThemeColors {
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F5F9);
  static const primary = Color(0xFF6366F1);
  static const onSurface = Color(0xFF0F172A);
  static const onSurfaceVariant = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}

/// Тёмная тема
class DarkThemeColors {
  static const background = Color(0xFF0A0E27);
  static const surface = Color(0xFF1E293B);
  static const surfaceVariant = Color(0xFF334155);
  static const primary = Color(0xFF6366F1);
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceVariant = Color(0xFF94A3B8);
  static const border = Color(0xFF334155);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}
