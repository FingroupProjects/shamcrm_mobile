import 'package:crm_task_manager/theme/app_theme_controller.dart';
import 'package:crm_task_manager/theme/app_theme_mode.dart';
import 'package:crm_task_manager/theme/app_theme_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppThemeController initializes and persists explicit mode changes',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final controller = AppThemeController(
      storage: AppThemeStorage(prefs),
    );

    await controller.initialize(AppThemeMode.system);
    expect(controller.mode, AppThemeMode.system);
    expect(controller.materialThemeMode, ThemeMode.system);

    await controller.setMode(AppThemeMode.dark);

    expect(controller.mode, AppThemeMode.dark);
    expect(controller.effectiveBrightness, Brightness.dark);
    expect(
      prefs.getString(AppThemeStorage.storageKey),
      AppThemeMode.dark.storageValue,
    );
  });
}
