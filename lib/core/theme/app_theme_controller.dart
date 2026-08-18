import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/background/wallpaper_rotation_mode.dart';
import 'package:crm_task_manager/core/theme/background/wallpaper_source.dart';
import 'package:crm_task_manager/core/theme/palette/app_palette.dart';
import 'package:crm_task_manager/core/theme/palette/app_palette_presets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WallpaperAdvanceReason { launch, resume, tick, manual }

class AppThemeController extends ChangeNotifier with WidgetsBindingObserver {
  AppThemeController._()
      : _themeMode = ThemeMode.system,
        _palettePreset = AppPalettePreset.analogous,
        _backgroundPreset = AppBackgroundPreset.none;

  static final AppThemeController instance = AppThemeController._();
  static const maxCarouselCount = 15;
  static const intervalPresets = [1, 5, 15, 30, 60, 120, 360];

  static const _themeModeKey = 'app_theme_mode_v1';
  static const _paletteKey = 'app_palette_preset_v1';
  static const _paletteSeedColorKey = 'app_palette_seed_color_v1';
  static const _backgroundKey = 'app_background_preset_v1';
  static const _backgroundImagePathKey = 'app_background_image_path_v1';
  static const _backgroundAssetPathKey = 'app_background_asset_path_v1';
  static const _backgroundBlurKey = 'app_background_blur_v1';
  static const _backgroundOpacityKey = 'app_background_opacity_v1';
  static const _loginIntroAnimationKey = 'app_login_intro_animation_v1';
  static const _legacyDefaultBackgroundClearedKey =
      'app_legacy_default_bg_cleared_v1';
  static const _libraryKey = 'app_wallpaper_library_v1';
  static const _carouselKey = 'app_wallpaper_carousel_v1';
  static const _rotationModeKey = 'app_wallpaper_rotation_mode_v1';
  static const _intervalMinutesKey = 'app_wallpaper_interval_minutes_v1';
  static const _carouselIndexKey = 'app_wallpaper_carousel_index_v1';
  static const _lastRotateMsKey = 'app_wallpaper_last_rotate_ms_v1';
  static const defaultBackgroundAssetPath = 'assets/fon/IMG_1620.JPG';

  ThemeMode _themeMode;
  AppPalettePreset _palettePreset;
  Color? _paletteSeedColor;
  AppBackgroundPreset _backgroundPreset;
  String? _backgroundImagePath;
  String? _backgroundAssetPath;
  double _backgroundBlurPercent = 18;
  double _backgroundOpacityPercent = 100;
  bool _loginIntroAnimationEnabled = true;
  bool _isInitialized = false;
  List<String> _importedLibraryPaths = [];
  List<WallpaperSource> _carouselItems = [];
  WallpaperRotationMode _rotationMode = WallpaperRotationMode.onLaunch;
  int _intervalMinutes = 30;
  int _carouselIndex = 0;
  int _lastRotateMs = 0;
  DateTime? _initializedAt;
  DateTime? _lastPausedAt;
  Timer? _rotationTimer;
  final Random _random = Random();

  ThemeMode get themeMode => _themeMode;
  AppPalettePreset get palettePreset => _palettePreset;
  AppBackgroundPreset get backgroundPreset => _backgroundPreset;
  String? get backgroundImagePath => _backgroundImagePath;
  String? get backgroundAssetPath => _backgroundAssetPath;
  double get backgroundBlurPercent => _backgroundBlurPercent;
  double get backgroundBlurSigma => _blurPercentToSigma(_backgroundBlurPercent);
  double get backgroundOpacityPercent => _backgroundOpacityPercent;
  double get backgroundOpacity =>
      (_backgroundOpacityPercent.clamp(10, 100) / 100);
  bool get loginIntroAnimationEnabled => _loginIntroAnimationEnabled;
  AppPalette get lightPalette =>
      _palettePreset.lightPaletteForSeed(_paletteSeedColor);
  AppPalette get darkPalette =>
      _palettePreset.darkPaletteForSeed(_paletteSeedColor);
  Color get paletteSeedColor => _paletteSeedColor ?? const Color(0xFF0EA5E9);
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  bool get isInitialized => _isInitialized;
  List<String> get importedLibraryPaths =>
      List.unmodifiable(_importedLibraryPaths);
  List<WallpaperSource> get carouselItems => List.unmodifiable(_carouselItems);
  WallpaperRotationMode get rotationMode => _rotationMode;
  int get intervalMinutes => _intervalMinutes;
  int get carouselIndex => _carouselIndex;
  bool get hasCarouselSelection => _carouselItems.isNotEmpty;
  bool get canAutoRotate => _carouselItems.length >= 2;
  bool get isCarouselActive =>
      _backgroundPreset == AppBackgroundPreset.custom &&
      _carouselItems.length >= 2;
  WallpaperSource? get currentCarouselSource {
    if (_carouselItems.isEmpty) return null;
    return _carouselItems[_carouselIndex.clamp(0, _carouselItems.length - 1)];
  }

  bool get hasCustomWallpaper {
    if (_backgroundPreset != AppBackgroundPreset.custom) return false;
    final image = _backgroundImagePath;
    final asset = _backgroundAssetPath;
    return (image != null && image.isNotEmpty) ||
        (asset != null && asset.isNotEmpty);
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _themeModeFromStorage(prefs.getString(_themeModeKey));
    _palettePreset =
        AppPalettePresetX.fromStorageKey(prefs.getString(_paletteKey));
    _paletteSeedColor = _parseColor(prefs.getString(_paletteSeedColorKey));
    final savedBackgroundPreset = prefs.getString(_backgroundKey);
    if (savedBackgroundPreset == null) {
      _backgroundPreset = AppBackgroundPreset.none;
      _backgroundAssetPath = null;
    } else {
      _backgroundPreset =
          AppBackgroundPresetX.fromStorageKey(savedBackgroundPreset);
      _backgroundAssetPath = prefs.getString(_backgroundAssetPathKey);
    }
    _backgroundImagePath = prefs.getString(_backgroundImagePathKey);
    _backgroundBlurPercent =
        prefs.getDouble(_backgroundBlurKey) ?? _backgroundBlurPercent;
    _backgroundOpacityPercent =
        prefs.getDouble(_backgroundOpacityKey) ?? _backgroundOpacityPercent;
    _loginIntroAnimationEnabled =
        prefs.getBool(_loginIntroAnimationKey) ?? _loginIntroAnimationEnabled;
    _importedLibraryPaths = prefs.getStringList(_libraryKey) ?? [];
    _carouselItems = _decodeCarousel(prefs.getString(_carouselKey));
    _rotationMode =
        WallpaperRotationModeX.fromStorageKey(prefs.getString(_rotationModeKey));
    _intervalMinutes = prefs.getInt(_intervalMinutesKey) ?? _intervalMinutes;
    _carouselIndex = prefs.getInt(_carouselIndexKey) ?? 0;
    _lastRotateMs = prefs.getInt(_lastRotateMsKey) ?? 0;

    await _sanitizeStoredWallpapers(prefs);

    if (_backgroundPreset == AppBackgroundPreset.custom &&
        ((_backgroundImagePath == null || _backgroundImagePath!.isEmpty) &&
            (_backgroundAssetPath == null || _backgroundAssetPath!.isEmpty))) {
      _backgroundPreset = AppBackgroundPreset.none;
    }
    if (!(prefs.getBool(_legacyDefaultBackgroundClearedKey) ?? false)) {
      if (_backgroundPreset == AppBackgroundPreset.custom &&
          _backgroundAssetPath == defaultBackgroundAssetPath &&
          (_backgroundImagePath == null || _backgroundImagePath!.isEmpty) &&
          _carouselItems.isEmpty) {
        _backgroundPreset = AppBackgroundPreset.none;
        _backgroundAssetPath = null;
        await prefs.setString(_backgroundKey, _backgroundPreset.storageKey);
        await prefs.remove(_backgroundAssetPathKey);
      }
      await prefs.setBool(_legacyDefaultBackgroundClearedKey, true);
    }

    await _migrateLegacyWallpaperIntoCarousel(prefs);
    _normalizeCarouselIndex();
    _syncCurrentWallpaperFromCarousel();
    await _persistCarouselState(prefs);

    _isInitialized = true;
    _initializedAt = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    await _advanceCarouselIfNeeded(WallpaperAdvanceReason.launch);
    _restartRotationTimer();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _lastPausedAt ??= DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    final initializedAt = _initializedAt;
    if (initializedAt != null &&
        DateTime.now().difference(initializedAt) < const Duration(seconds: 3)) {
      _lastPausedAt = null;
      return;
    }
    final pausedAt = _lastPausedAt;
    _lastPausedAt = null;
    if (pausedAt != null &&
        DateTime.now().difference(pausedAt) < const Duration(seconds: 2)) {
      return;
    }
    unawaited(_advanceCarouselIfNeeded(WallpaperAdvanceReason.resume));
  }

  /// Warm the wallpaper image cache before the first Flutter frame so the
  /// PIN/login screens don't flash the solid theme color.
  Future<void> precacheBackground() async {
    if (_backgroundPreset != AppBackgroundPreset.custom) return;

    try {
      if (_backgroundImagePath != null && _backgroundImagePath!.isNotEmpty) {
        final file = File(_backgroundImagePath!);
        if (!file.existsSync()) return;
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        await codec.getNextFrame();
        return;
      }

      if (_backgroundAssetPath != null && _backgroundAssetPath!.isNotEmpty) {
        final data = await rootBundle.load(_backgroundAssetPath!);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
        );
        await codec.getNextFrame();
      }
    } catch (_) {
      // Best-effort: a failed precache must never block app start.
    }
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
    if (preset == AppBackgroundPreset.custom) {
      _syncCurrentWallpaperFromCarousel();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundKey, preset.storageKey);
    _restartRotationTimer();
    notifyListeners();
  }

  Future<void> setCustomBackgroundImagePath(String path) async {
    final persistedPath = await _persistLibraryImage(path);
    if (!_importedLibraryPaths.contains(persistedPath)) {
      _importedLibraryPaths = [..._importedLibraryPaths, persistedPath];
    }
    await _setCarouselItems([
      WallpaperSource(path: persistedPath, isAsset: false),
    ]);
  }

  Future<void> setAssetBackgroundImagePath(String assetPath) async {
    await _setCarouselItems([
      WallpaperSource(path: assetPath, isAsset: true),
    ]);
  }

  Future<int> importGalleryImages(List<String> sourcePaths) async {
    if (sourcePaths.isEmpty) return 0;
    final imported = <String>[];
    for (var i = 0; i < sourcePaths.length; i++) {
      try {
        final persisted =
            await _persistLibraryImage(sourcePaths[i], index: i);
        if (!_importedLibraryPaths.contains(persisted) &&
            !imported.contains(persisted)) {
          imported.add(persisted);
        }
      } catch (_) {
        // Skip unreadable gallery files and keep importing the rest.
      }
    }
    if (imported.isEmpty) return 0;
    _importedLibraryPaths = [...imported, ..._importedLibraryPaths];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_libraryKey, _importedLibraryPaths);
    notifyListeners();
    return imported.length;
  }

  bool isCarouselSourceSelected(WallpaperSource source) {
    return _carouselItems.any((item) => item.path == source.path);
  }

  int carouselOrderOf(WallpaperSource source) {
    return _carouselItems.indexWhere((item) => item.path == source.path);
  }

  Future<bool> toggleCarouselSource(WallpaperSource source) async {
    if (source.path.isEmpty) return false;
    final existingIndex =
        _carouselItems.indexWhere((item) => item.path == source.path);
    if (existingIndex >= 0) {
      final nextItems = [..._carouselItems]..removeAt(existingIndex);
      await _setCarouselItems(nextItems, keepCurrentIfPossible: true);
      return true;
    }
    if (_carouselItems.length >= maxCarouselCount) {
      return false;
    }
    await _setCarouselItems([..._carouselItems, source]);
    return true;
  }

  Future<void> activateCarousel() async {
    if (_carouselItems.isEmpty) return;
    await setBackgroundPreset(AppBackgroundPreset.custom);
  }

  Future<void> removeImportedSource(String path) async {
    if (path.isEmpty) return;
    _importedLibraryPaths =
        _importedLibraryPaths.where((item) => item != path).toList();
    final nextItems =
        _carouselItems.where((item) => item.path != path).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_libraryKey, _importedLibraryPaths);
    await _setCarouselItems(nextItems, keepCurrentIfPossible: true, prefs: prefs);
    await _deleteStoredBackgroundIfOwned(path);
  }

  Future<void> clearCarouselSelection() async {
    await _setCarouselItems(const []);
  }

  Future<void> setRotationMode(WallpaperRotationMode mode) async {
    if (_rotationMode == mode) return;
    _rotationMode = mode;
    _lastRotateMs = DateTime.now().millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rotationModeKey, mode.storageKey);
    await prefs.setInt(_lastRotateMsKey, _lastRotateMs);
    _restartRotationTimer();
    notifyListeners();
  }

  Future<void> setIntervalMinutes(int minutes) async {
    final normalized = minutes.clamp(1, 24 * 60);
    if (_intervalMinutes == normalized) return;
    _intervalMinutes = normalized;
    _lastRotateMs = DateTime.now().millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_intervalMinutesKey, _intervalMinutes);
    await prefs.setInt(_lastRotateMsKey, _lastRotateMs);
    _restartRotationTimer();
    notifyListeners();
  }

  Future<void> setBackgroundOpacityPercent(double value) async {
    final normalized = value.clamp(10, 100).toDouble();
    if (_backgroundOpacityPercent == normalized) return;
    _backgroundOpacityPercent = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_backgroundOpacityKey, _backgroundOpacityPercent);
    notifyListeners();
  }

  Future<void> showNextWallpaper() {
    return _advanceCarousel(
      shuffle: false,
      reverse: false,
    );
  }

  Future<void> showPreviousWallpaper() {
    return _advanceCarousel(
      shuffle: false,
      reverse: true,
    );
  }

  Future<void> clearCustomBackgroundImage() async {
    await _setCarouselItems(const []);
  }

  Future<void> resetAppearance() async {
    final libraryToDelete = [..._importedLibraryPaths];
    _themeMode = ThemeMode.system;
    _palettePreset = AppPalettePreset.analogous;
    _paletteSeedColor = null;
    _backgroundPreset = AppBackgroundPreset.none;
    _backgroundImagePath = null;
    _backgroundAssetPath = null;
    _backgroundBlurPercent = 18;
    _backgroundOpacityPercent = 100;
    _importedLibraryPaths = [];
    _carouselItems = [];
    _rotationMode = WallpaperRotationMode.onLaunch;
    _intervalMinutes = 30;
    _carouselIndex = 0;
    _lastRotateMs = 0;
    _rotationTimer?.cancel();
    _rotationTimer = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToStorage(_themeMode));
    await prefs.setString(_paletteKey, _palettePreset.storageKey);
    await prefs.remove(_paletteSeedColorKey);
    await prefs.setString(_backgroundKey, _backgroundPreset.storageKey);
    await prefs.remove(_backgroundImagePathKey);
    await prefs.remove(_backgroundAssetPathKey);
    await prefs.setDouble(_backgroundBlurKey, _backgroundBlurPercent);
    await prefs.setDouble(_backgroundOpacityKey, _backgroundOpacityPercent);
    await prefs.remove(_libraryKey);
    await prefs.remove(_carouselKey);
    await prefs.remove(_rotationModeKey);
    await prefs.remove(_intervalMinutesKey);
    await prefs.remove(_carouselIndexKey);
    await prefs.remove(_lastRotateMsKey);
    for (final path in libraryToDelete) {
      await _deleteStoredBackgroundIfOwned(path);
    }
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

  Future<void> setLoginIntroAnimationEnabled(bool enabled) async {
    if (_loginIntroAnimationEnabled == enabled) return;
    _loginIntroAnimationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginIntroAnimationKey, enabled);
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

  Future<void> _setCarouselItems(
    List<WallpaperSource> items, {
    bool keepCurrentIfPossible = false,
    SharedPreferences? prefs,
  }) async {
    final previousCurrent = currentCarouselSource;
    final unique = <String, WallpaperSource>{};
    for (final item in items) {
      if (item.path.isEmpty) continue;
      unique[item.path] = item;
      if (unique.length >= maxCarouselCount) break;
    }
    _carouselItems = unique.values.toList();
    if (_carouselItems.isEmpty) {
      _carouselIndex = 0;
      _backgroundImagePath = null;
      _backgroundAssetPath = null;
      if (_backgroundPreset == AppBackgroundPreset.custom) {
        _backgroundPreset = AppBackgroundPreset.none;
      }
    } else {
      if (keepCurrentIfPossible && previousCurrent != null) {
        final keptIndex = _carouselItems
            .indexWhere((item) => item.path == previousCurrent.path);
        _carouselIndex = keptIndex >= 0 ? keptIndex : 0;
      } else if (_carouselIndex >= _carouselItems.length) {
        _carouselIndex = 0;
      }
      _backgroundPreset = AppBackgroundPreset.custom;
      _syncCurrentWallpaperFromCarousel();
    }
    if (_lastRotateMs == 0) {
      _lastRotateMs = DateTime.now().millisecondsSinceEpoch;
    }
    final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
    await _persistCarouselState(resolvedPrefs);
    _restartRotationTimer();
    notifyListeners();
  }

  Future<void> _advanceCarouselIfNeeded(WallpaperAdvanceReason reason) async {
    if (_carouselItems.length < 2 ||
        _backgroundPreset != AppBackgroundPreset.custom) {
      return;
    }

    switch (_rotationMode) {
      case WallpaperRotationMode.manual:
        return;
      case WallpaperRotationMode.onLaunch:
        if (reason == WallpaperAdvanceReason.launch ||
            reason == WallpaperAdvanceReason.resume) {
          await _advanceCarousel(shuffle: false);
        }
        return;
      case WallpaperRotationMode.shuffleOnLaunch:
        if (reason == WallpaperAdvanceReason.launch ||
            reason == WallpaperAdvanceReason.resume) {
          await _advanceCarousel(shuffle: true);
        }
        return;
      case WallpaperRotationMode.interval:
        if (_hasIntervalElapsed()) {
          await _advanceCarousel(shuffle: false);
        }
        return;
      case WallpaperRotationMode.daily:
        if (_hasCalendarDayChanged()) {
          await _advanceCarousel(shuffle: false);
        }
        return;
    }
  }

  Future<void> _advanceCarousel({
    required bool shuffle,
    bool reverse = false,
  }) async {
    if (_carouselItems.length < 2) return;
    if (shuffle) {
      var next = _random.nextInt(_carouselItems.length);
      if (next == _carouselIndex && _carouselItems.length > 1) {
        next = (next + 1) % _carouselItems.length;
      }
      _carouselIndex = next;
    } else {
      final delta = reverse ? -1 : 1;
      _carouselIndex =
          (_carouselIndex + delta) % _carouselItems.length;
      if (_carouselIndex < 0) {
        _carouselIndex += _carouselItems.length;
      }
    }
    _lastRotateMs = DateTime.now().millisecondsSinceEpoch;
    _syncCurrentWallpaperFromCarousel();
    final prefs = await SharedPreferences.getInstance();
    await _persistCarouselState(prefs);
    unawaited(_precacheAdjacentWallpaper());
    notifyListeners();
  }

  bool _hasIntervalElapsed() {
    if (_lastRotateMs <= 0) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - _lastRotateMs;
    return elapsed >= _intervalMinutes * 60 * 1000;
  }

  bool _hasCalendarDayChanged() {
    if (_lastRotateMs <= 0) return false;
    final last = DateTime.fromMillisecondsSinceEpoch(_lastRotateMs);
    final now = DateTime.now();
    return last.year != now.year ||
        last.month != now.month ||
        last.day != now.day;
  }

  void _restartRotationTimer() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
    if (_rotationMode != WallpaperRotationMode.interval ||
        _carouselItems.length < 2 ||
        _backgroundPreset != AppBackgroundPreset.custom) {
      return;
    }
    final intervalMs = _intervalMinutes * 60 * 1000;
    final elapsed = _lastRotateMs <= 0
        ? 0
        : DateTime.now().millisecondsSinceEpoch - _lastRotateMs;
    final remaining = (intervalMs - elapsed).clamp(1000, intervalMs);
    _rotationTimer = Timer(Duration(milliseconds: remaining), () async {
      await _advanceCarouselIfNeeded(WallpaperAdvanceReason.tick);
      _restartRotationTimer();
    });
  }

  void _syncCurrentWallpaperFromCarousel() {
    final current = currentCarouselSource;
    if (current == null) {
      _backgroundImagePath = null;
      _backgroundAssetPath = null;
      return;
    }
    if (current.isAsset) {
      _backgroundAssetPath = current.path;
      _backgroundImagePath = null;
      return;
    }
    _backgroundImagePath = current.path;
    _backgroundAssetPath = null;
  }

  void _normalizeCarouselIndex() {
    if (_carouselItems.isEmpty) {
      _carouselIndex = 0;
      return;
    }
    if (_carouselIndex < 0 || _carouselIndex >= _carouselItems.length) {
      _carouselIndex = 0;
    }
  }

  Future<void> _sanitizeStoredWallpapers(SharedPreferences prefs) async {
    final validLibrary = <String>[];
    for (final path in _importedLibraryPaths) {
      if (path.isNotEmpty && File(path).existsSync()) {
        validLibrary.add(path);
      }
    }
    _importedLibraryPaths = validLibrary;

    _carouselItems = _carouselItems.where((item) {
      if (item.path.isEmpty) return false;
      if (item.isAsset) return true;
      return File(item.path).existsSync();
    }).toList();

    if (_backgroundImagePath != null && _backgroundImagePath!.isNotEmpty) {
      if (!File(_backgroundImagePath!).existsSync()) {
        _backgroundImagePath = null;
        if (_backgroundPreset == AppBackgroundPreset.custom &&
            (_backgroundAssetPath == null || _backgroundAssetPath!.isEmpty) &&
            _carouselItems.isEmpty) {
          _backgroundPreset = AppBackgroundPreset.none;
        }
        await prefs.remove(_backgroundImagePathKey);
      }
    }
  }

  Future<void> _migrateLegacyWallpaperIntoCarousel(
    SharedPreferences prefs,
  ) async {
    if (_carouselItems.isNotEmpty) return;
    if (_backgroundImagePath != null &&
        _backgroundImagePath!.isNotEmpty &&
        File(_backgroundImagePath!).existsSync()) {
      if (!_importedLibraryPaths.contains(_backgroundImagePath)) {
        _importedLibraryPaths = [
          ..._importedLibraryPaths,
          _backgroundImagePath!,
        ];
      }
      _carouselItems = [
        WallpaperSource(path: _backgroundImagePath!, isAsset: false),
      ];
      return;
    }
    if (_backgroundAssetPath != null && _backgroundAssetPath!.isNotEmpty) {
      _carouselItems = [
        WallpaperSource(path: _backgroundAssetPath!, isAsset: true),
      ];
    }
  }

  Future<void> _persistCarouselState(SharedPreferences prefs) async {
    await prefs.setStringList(_libraryKey, _importedLibraryPaths);
    await prefs.setString(
      _carouselKey,
      jsonEncode(_carouselItems.map((item) => item.toJson()).toList()),
    );
    await prefs.setString(_rotationModeKey, _rotationMode.storageKey);
    await prefs.setInt(_intervalMinutesKey, _intervalMinutes);
    await prefs.setInt(_carouselIndexKey, _carouselIndex);
    await prefs.setInt(_lastRotateMsKey, _lastRotateMs);
    await prefs.setString(_backgroundKey, _backgroundPreset.storageKey);
    if (_backgroundImagePath != null && _backgroundImagePath!.isNotEmpty) {
      await prefs.setString(_backgroundImagePathKey, _backgroundImagePath!);
    } else {
      await prefs.remove(_backgroundImagePathKey);
    }
    if (_backgroundAssetPath != null && _backgroundAssetPath!.isNotEmpty) {
      await prefs.setString(_backgroundAssetPathKey, _backgroundAssetPath!);
    } else {
      await prefs.remove(_backgroundAssetPathKey);
    }
  }

  List<WallpaperSource> _decodeCarousel(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => WallpaperSource.fromJson(
                item.cast<String, dynamic>(),
              ))
          .where((item) => item.path.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _precacheAdjacentWallpaper() async {
    if (_carouselItems.length < 2) return;
    final next = _carouselItems[(_carouselIndex + 1) % _carouselItems.length];
    try {
      if (next.isAsset) {
        final data = await rootBundle.load(next.path);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
        );
        await codec.getNextFrame();
        return;
      }
      final file = File(next.path);
      if (!file.existsSync()) return;
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      await codec.getNextFrame();
    } catch (_) {}
  }

  Future<String> _persistLibraryImage(String sourcePath, {int index = 0}) async {
    final sourceFile = File(sourcePath);
    final appDir = await getApplicationDocumentsDirectory();
    final themeDir = Directory('${appDir.path}/theme_backgrounds');
    if (!themeDir.existsSync()) {
      await themeDir.create(recursive: true);
    }

    final extension = _extractExtension(sourcePath);
    final fileName =
        'library_${DateTime.now().microsecondsSinceEpoch}_$index$extension';
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
