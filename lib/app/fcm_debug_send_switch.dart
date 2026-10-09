import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Галочка «Тестовый» на экране входа в debug-сборке.
///
/// true — тестовый вход. POST /add-fcm-token не уходит.
/// Так токен клиента на сервере не заменяется токеном телефона или эмулятора.
/// false — обычный вход. Токен отправляется, если Firebase его выдал.
///
/// В release и profile галочка не показывается, токен уходит всегда.
const String debugTestLoginPrefsKey = 'debug_test_login_skip_fcm';

/// Память на время запуска. До чтения настроек считаем вход тестовым.
bool debugTestLogin = true;

Future<void>? _debugTestLoginLoad;

/// Можно ли сейчас вызвать add-fcm-token.
///
/// Сначала вызовите [ensureDebugTestLoginLoaded], чтобы взять значение галочки.
bool get allowAddFcmTokenUpload => !kDebugMode || !debugTestLogin;

/// Читает галочку один раз за запуск. По умолчанию она включена.
Future<void> ensureDebugTestLoginLoaded() {
  if (!kDebugMode) {
    return Future<void>.value();
  }
  return _debugTestLoginLoad ??= _readDebugTestLogin();
}

Future<void> _readDebugTestLogin() async {
  final prefs = await SharedPreferences.getInstance();
  debugTestLogin = prefs.getBool(debugTestLoginPrefsKey) ?? true;
}

/// Сохраняет галочку сразу, до входа по QR или почте.
Future<void> setDebugTestLogin(bool value) async {
  debugTestLogin = value;
  if (!kDebugMode) {
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(debugTestLoginPrefsKey, value);
}
