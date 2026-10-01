import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Кэш флага `change_lead_manager` из `/get-user-data`.
///
/// true — менеджера лида можно выбрать вручную.
/// false — поле только для просмотра.
/// null — ответ ещё не приходил, поле пока не трогаем.
class ChangeLeadManagerStore {
  static const String prefsKey = 'change_lead_manager';

  /// Живое значение. Формы лида слушают его и не ждут повторный заход.
  static final ValueNotifier<bool?> canChange = ValueNotifier<bool?>(null);

  /// Берём последнее сохранённое значение, если сервер уже отвечал.
  static Future<void> hydrateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(prefsKey)) return;
      canChange.value = prefs.getBool(prefsKey) ?? false;
    } catch (error) {
      debugPrint('ChangeLeadManagerStore: hydrate error: $error');
    }
  }

  /// Пишем и true, и false: право могли забрать.
  static Future<void> save(bool value) async {
    canChange.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, value);
    } catch (error) {
      debugPrint('ChangeLeadManagerStore: save error: $error');
    }
  }
}
