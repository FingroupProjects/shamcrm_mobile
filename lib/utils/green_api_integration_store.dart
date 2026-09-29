import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Кэш флага WhatsApp (Green API) из `/get-user-data`.
/// Нужен в карточке лида: показывать ли канал WhatsApp для первого сообщения.
class GreenApiIntegrationStore {
  static const String prefsKey = 'has_green_api_integration';

  /// Live-флаг. Экран лида читает его без повторного запроса.
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  /// Читаем сохранённое значение, чтобы кнопка не ждала сеть.
  static Future<void> hydrateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(prefsKey) ?? false;
    } catch (error) {
      debugPrint('GreenApiIntegrationStore: hydrate error: $error');
    }
  }

  /// Сохраняем ответ сервера. false тоже пишем — интеграцию могли выключить.
  static Future<void> save(bool value) async {
    enabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, value);
    } catch (error) {
      debugPrint('GreenApiIntegrationStore: save error: $error');
    }
  }
}
