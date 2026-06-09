import 'package:flutter/material.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._() : _themeMode = ThemeMode.light;

  static final AppThemeController instance = AppThemeController._();

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => false;
  bool get isSystemMode => false;

  void toggleTheme() {
    if (_themeMode != ThemeMode.light) {
      _themeMode = ThemeMode.light;
      notifyListeners();
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == ThemeMode.light) {
      return;
    }
    _themeMode = ThemeMode.light;
    notifyListeners();
  }
}
