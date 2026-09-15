import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Кэш флага ИИ-интеграции из `/get-user-data`.
/// Кнопка генерации в чате слушает [enabled] и появляется сразу после PIN.
class AiIntegrationStore {
  static const String prefsKey = 'has_ai_integration';

  /// Live-флаг: чат обновляет кнопку без перезахода в экран.
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  /// Читаем сохранённое значение, чтобы кнопка не ждала повторный запрос.
  static Future<void> hydrateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(prefsKey) ?? false;
    } catch (error) {
      debugPrint('AiIntegrationStore: hydrate error: $error');
    }
  }

  /// Сохраняем ответ сервера. false тоже пишем — интеграцию могли выключить.
  static Future<void> save(bool value) async {
    enabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, value);
    } catch (error) {
      debugPrint('AiIntegrationStore: save error: $error');
    }
  }
}
