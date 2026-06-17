import 'dart:io';

import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/palette/app_palette.dart';
import 'package:crm_task_manager/core/theme/palette/app_palette_presets.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._()
      : _themeMode = ThemeMode.system,
        _palettePreset = AppPalettePreset.analogous,
        _backgroundPreset = AppBackgroundPreset.none;

  static final AppThemeController instance = AppThemeController._();
  static const _themeModeKey = 'app_theme_mode_v1';
  static const _paletteKey = 'app_palette_preset_v1';
  static const _paletteSeedColorKey = 'app_palette_seed_color_v1';
  static const _backgroundKey = 'app_background_preset_v1';
  static const _backgroundImagePathKey = 'app_background_image_path_v1';
  static const _backgroundAssetPathKey = 'app_background_asset_path_v1';
  static const _backgroundBlurKey = 'app_background_blur_v1';

  ThemeMode _themeMode;
  AppPalettePreset _palettePreset;
  Color? _paletteSeedColor;
  AppBackgroundPreset _backgroundPreset;
  String? _backgroundImagePath;
  String? _backgroundAssetPath;
  double _backgroundBlurPercent = 18;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  AppPalettePreset get palettePreset => _palettePreset;
  AppBackgroundPreset get backgroundPreset => _backgroundPreset;
  String? get backgroundImagePath => _backgroundImagePath;
  String? get backgroundAssetPath => _backgroundAssetPath;
  double get backgroundBlurPercent => _backgroundBlurPercent;
  double get backgroundBlurSigma => _blurPercentToSigma(_backgroundBlurPercent);
  AppPalette get lightPalette =>
      _palettePreset.lightPaletteForSeed(_paletteSeedColor);
  AppPalette get darkPalette =>
      _palettePreset.darkPaletteForSeed(_paletteSeedColor);
  Color get paletteSeedColor => _paletteSeedColor ?? const Color(0xFF0EA5E9);
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _themeModeFromStorage(prefs.getString(_themeModeKey));
    _palettePreset =
        AppPalettePresetX.fromStorageKey(prefs.getString(_paletteKey));
    _paletteSeedColor = _parseColor(prefs.getString(_paletteSeedColorKey));
    _backgroundPreset =
        AppBackgroundPresetX.fromStorageKey(prefs.getString(_backgroundKey));
    _backgroundImagePath = prefs.getString(_backgroundImagePathKey);
    _backgroundAssetPath = prefs.getString(_backgroundAssetPathKey);
    _backgroundBlurPercent =
        prefs.getDouble(_backgroundBlurKey) ?? _backgroundBlurPercent;
    if (_backgroundPreset == AppBackgroundPreset.custom &&
        ((_backgroundImagePath == null || _backgroundImagePath!.isEmpty) &&
            (_backgroundAssetPath == null || _backgroundAssetPath!.isEmpty))) {
      _backgroundPreset = AppBackgroundPreset.none;
    }
    if (_backgroundImagePath != null && _backgroundImagePath!.isNotEmpty) {
      final file = File(_backgroundImagePath!);
      if (!file.existsSync()) {
        _backgroundImagePath = null;
        if (_backgroundPreset == AppBackgroundPreset.custom) {
          _backgroundPreset = AppBackgroundPreset.none;
        }
        await prefs.remove(_backgroundImagePathKey);
        await prefs.remove(_backgroundAssetPathKey);
        await prefs.setString(_backgroundKey, _backgroundPreset.storageKey);
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final nextMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToStorage(mode));
    notifyListeners();
  }

  Future<void> setPalettePreset(AppPalettePreset preset) async {
    if (_palettePreset == preset) return;
    _palettePreset = preset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, preset.storageKey);
    notifyListeners();
  }

  Future<void> setPaletteSeedColor(Color color) async {
    _paletteSeedColor = color;
    _palettePreset = AppPalettePreset.custom;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, _palettePreset.storageKey);
    await prefs.setString(_paletteSeedColorKey, _colorToHex(color));
    notifyListeners();
  }

  Future<void> setBackgroundPreset(AppBackgroundPreset preset) async {
    if (_backgroundPreset == preset) return;
    _backgroundPreset = preset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundKey, preset.storageKey);
    notifyListeners();
  }

  Future<void> setCustomBackgroundImagePath(String path) async {
    final persistedPath = await _persistCustomBackgroundImage(path);
    final previousPath = _backgroundImagePath;
    _backgroundImagePath = persistedPath;
    _backgroundAssetPath = null;
    _backgroundPreset = AppBackgroundPreset.custom;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundImagePathKey, persistedPath);
    await prefs.remove(_backgroundAssetPathKey);
    await prefs.setString(_backgroundKey, _backgroundPreset.storageKey);
    await _deleteStoredBackgroundIfOwned(previousPath,
        excludePath: persistedPath);
    notifyListeners();
  }

  Future<void> setAssetBackgroundImagePath(String assetPath) async {
    _backgroundAssetPath = assetPath;
    _backgroundImagePath = null;
    _backgroundPreset = AppBackgroundPreset.custom;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundAssetPathKey, assetPath);
    await prefs.remove(_backgroundImagePathKey);
    await prefs.setString(_backgroundKey, _backgroundPreset.storageKey);
    notifyListeners();
  }

  Future<void> clearCustomBackgroundImage() async {
    final previousPath = _backgroundImagePath;
    _backgroundImagePath = null;
    _backgroundAssetPath = null;
    if (_backgroundPreset == AppBackgroundPreset.custom) {
      _backgroundPreset = AppBackgroundPreset.none;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backgroundImagePathKey);
    await prefs.remove(_backgroundAssetPathKey);
    await prefs.setString(_backgroundKey, _backgroundPreset.storageKey);
    await _deleteStoredBackgroundIfOwned(previousPath);
    notifyListeners();
  }

  Future<void> resetAppearance() async {
    final previousPath = _backgroundImagePath;
    _themeMode = ThemeMode.system;
    _palettePreset = AppPalettePreset.analogous;
    _paletteSeedColor = null;
    _backgroundPreset = AppBackgroundPreset.none;
    _backgroundImagePath = null;
    _backgroundAssetPath = null;
    _backgroundBlurPercent = 18;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToStorage(_themeMode));
    await prefs.setString(_paletteKey, _palettePreset.storageKey);
    await prefs.remove(_paletteSeedColorKey);
    await prefs.setString(_backgroundKey, _backgroundPreset.storageKey);
    await prefs.remove(_backgroundImagePathKey);
    await prefs.remove(_backgroundAssetPathKey);
    await prefs.setDouble(_backgroundBlurKey, _backgroundBlurPercent);
    await _deleteStoredBackgroundIfOwned(previousPath);
    notifyListeners();
  }

  String _colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0');
  }

  Color? _parseColor(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.startsWith('0x') ? value.substring(2) : value;
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }

  Future<void> setBackgroundBlurPercent(double value) async {
    final normalized = value.clamp(0, 100).toDouble();
    if (_backgroundBlurPercent == normalized) return;
    _backgroundBlurPercent = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_backgroundBlurKey, _backgroundBlurPercent);
    notifyListeners();
  }

  ThemeMode _themeModeFromStorage(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }

  Future<String> _persistCustomBackgroundImage(String sourcePath) async {
    final sourceFile = File(sourcePath);
    final appDir = await getApplicationDocumentsDirectory();
    final themeDir = Directory('${appDir.path}/theme_backgrounds');
    if (!themeDir.existsSync()) {
      await themeDir.create(recursive: true);
    }

    final extension = _extractExtension(sourcePath);
    final fileName =
        'background_${DateTime.now().millisecondsSinceEpoch}$extension';
    final targetPath = '${themeDir.path}/$fileName';
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  String _extractExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1) {
      return '.jpg';
    }
    return path.substring(dotIndex);
  }

  Future<void> _deleteStoredBackgroundIfOwned(
    String? path, {
    String? excludePath,
  }) async {
    if (path == null || path.isEmpty || path == excludePath) {
      return;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final normalizedAppPath = appDir.path;
    if (!path.startsWith(normalizedAppPath)) {
      return;
    }
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  double _blurPercentToSigma(double percent) {
    return (percent.clamp(0, 100) / 100) * 32;
  }
}
