import 'package:flutter/material.dart';

enum AppThemeMode {
  system,
  light,
  dark,
}

extension AppThemeModeX on AppThemeMode {
  ThemeMode get materialThemeMode {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  String get storageValue {
    switch (this) {
      case AppThemeMode.system:
        return 'system';
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
    }
  }

  Brightness get explicitBrightness {
    switch (this) {
      case AppThemeMode.system:
        return Brightness.light;
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
    }
  }

  static AppThemeMode fromStorageValue(String? value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }
}
