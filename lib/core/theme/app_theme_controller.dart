import 'package:flutter/material.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._()
      : _themeMode =
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                    Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light;

  static final AppThemeController instance = AppThemeController._();

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
  }
}
