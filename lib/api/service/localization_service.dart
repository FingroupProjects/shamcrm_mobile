import 'package:crm_task_manager/api/service/widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _languageKey = 'selected_language';
  static const String _dialCodeKey = 'default_dial_code';
  
  /// Сохранить язык из API
  static Future<void> saveLanguageFromApi(String languageCode) async {
    // Проверяем что язык поддерживается
    if (!['ru', 'en', 'uz'].contains(languageCode)) {
      languageCode = 'ru'; // По умолчанию русский
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    
    // Синхронизируем с виджетом
    await WidgetService.syncLanguageToWidget(languageCode);
  }
  
  /// Сохранить телефонный код из API
  static Future<void> saveDialCodeFromApi(String dialCode) async {
    // Убедимся что код начинается с '+'
    if (!dialCode.startsWith('+')) {
      dialCode = '+$dialCode';
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dialCodeKey, dialCode);
  }
  
  /// Применить настройки локализации (язык + телефонный код)
  static Future<void> applyLocalizationSettings({
    required String language,
    required String phoneCode,
  }) async {
    await saveLanguageFromApi(language);
    await saveDialCodeFromApi(phoneCode);
  }
  
  /// Получить текущий язык
  static Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }
  
  /// Получить текущий телефонный код
  static Future<String?> getDialCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dialCodeKey);
  }
  
  /// Проверить применены ли настройки локализации
  static Future<bool> hasLocalizationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_languageKey) && prefs.containsKey(_dialCodeKey);
  }
}
