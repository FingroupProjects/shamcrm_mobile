import 'package:crm_task_manager/theme/app_theme_mode.dart';
import 'package:crm_task_manager/theme/app_theme_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppThemeStorage loads system by default and persists selected mode',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final storage = AppThemeStorage(prefs);

    expect(storage.loadMode(), AppThemeMode.system);

    await storage.saveMode(AppThemeMode.dark);

    expect(storage.loadMode(), AppThemeMode.dark);
    expect(
      prefs.getString(AppThemeStorage.storageKey),
      AppThemeMode.dark.storageValue,
    );
  });
}
