import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Кэш права `change_lead_manager` из `/get-user-data`.
///
/// В ответе это строка внутри `permissions`, не отдельное поле.
/// true — строка есть, менеджера лида можно выбрать вручную.
/// false — строки нет, поле только для просмотра.
/// null — ответ ещё не приходил, поле пока не трогаем.
class ChangeLeadManagerStore {
  static const String prefsKey = 'change_lead_manager';
  static const String permissionName = 'change_lead_manager';

  /// Живое значение. Формы лида слушают его и не ждут повторный заход.
  static final ValueNotifier<bool?> canChange = ValueNotifier<bool?>(null);

  /// Берём последнее сохранённое значение, если сервер уже отвечал.
  ///
  /// Старый кэш — это bool, и он записывался как false,
  /// потому что отдельного поля в ответе нет.
  /// Если в сохранённом списке прав строка уже есть, поле открываем сразу.
  static Future<void> hydrateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissions = prefs.getStringList('permissions');
      if (permissions != null && permissions.contains(permissionName)) {
        canChange.value = true;
        return;
      }
      if (!prefs.containsKey(prefsKey)) return;
      canChange.value = prefs.getBool(prefsKey) ?? false;
    } catch (error) {
      debugPrint('ChangeLeadManagerStore: hydrate error: $error');
    }
  }

  /// Есть ли право менять менеджера лида в теле `/get-user-data`.
  ///
  /// Право — строка внутри `permissions`.
  /// Строка есть — поле можно редактировать.
  /// Строки нет — поле закрыто.
  /// Отдельное булево поле не читаем: в ответе его нет.
  static bool allowsChange(Map<dynamic, dynamic> body) {
    if (_listHasPermission(body['permissions'])) return true;

    final result = body['result'];
    if (result is Map && _listHasPermission(result['permissions'])) {
      return true;
    }
    return false;
  }

  /// Сохранённый список прав с логина и с экрана прав.
  /// Та же строка, что и в `/get-user-data`.
  static bool allowsChangeFromList(Iterable<String> permissions) {
    return permissions.contains(permissionName);
  }

  static bool _listHasPermission(dynamic permissions) {
    if (permissions is! List) return false;
    for (final item in permissions) {
      if (item?.toString() == permissionName) return true;
    }
    return false;
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
