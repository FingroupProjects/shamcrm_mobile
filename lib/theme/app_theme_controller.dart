import 'package:crm_task_manager/theme/app_theme_mode.dart';
import 'package:crm_task_manager/theme/app_theme_storage.dart';
import 'package:flutter/material.dart';

class AppThemeController extends ChangeNotifier with WidgetsBindingObserver {
  AppThemeController({
    required AppThemeStorage storage,
  })  : _storage = storage,
        _platformBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;

  final AppThemeStorage _storage;

  AppThemeMode _mode = AppThemeMode.system;
  Brightness _platformBrightness;
  bool _isInitialized = false;

  AppThemeMode get mode => _mode;
  bool get isInitialized => _isInitialized;
  ThemeMode get materialThemeMode => _mode.materialThemeMode;

  Brightness get effectiveBrightness {
    if (_mode == AppThemeMode.system) {
      return _platformBrightness;
    }
    return _mode.explicitBrightness;
  }

  Future<void> initialize(AppThemeMode initialMode) async {
    if (_isInitialized) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _mode = initialMode;
    _platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    await _storage.saveMode(mode);
    notifyListeners();
  }

  Future<void> toggleLightDark() async {
    final nextMode = effectiveBrightness == Brightness.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    await setMode(nextMode);
  }

  @override
  void didChangePlatformBrightness() {
    final nextBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (_platformBrightness == nextBrightness) {
      return;
    }
    _platformBrightness = nextBrightness;
    if (_mode == AppThemeMode.system) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
