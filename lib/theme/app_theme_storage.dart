import 'package:crm_task_manager/theme/app_theme_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeStorage {
  AppThemeStorage(this._prefs);

  static const String storageKey = 'app_theme_mode';

  final SharedPreferences _prefs;

  static Future<AppThemeStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppThemeStorage(prefs);
  }

  AppThemeMode loadMode() {
    return AppThemeModeX.fromStorageValue(_prefs.getString(storageKey));
  }

  Future<void> saveMode(AppThemeMode mode) {
    return _prefs.setString(storageKey, mode.storageValue);
  }
}
