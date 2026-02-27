import 'dart:convert';

import 'package:crm_task_manager/models/localization_model.dart';
import 'package:crm_task_manager/api/service/widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _languageKey = 'selected_language';
  static const String _dialCodeKey = 'default_dial_code';
  static const String _currencyIdKey = 'currency_id';
  static const String _currencyNameKey = 'currency_name';
  static const String _currencyDigitalCodeKey = 'currency_digital_code';
  static const String _currencySymbolCodeKey = 'currency_symbol_code';
  static const String _currencyJsonKey = 'currency_data';
  
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
    LocalizationCurrency? currency,
  }) async {
    await saveLanguageFromApi(language);
    await saveDialCodeFromApi(phoneCode);
    await saveCurrencyFromApi(currency);
  }

  /// Сохранить валюту из API
  static Future<void> saveCurrencyFromApi(LocalizationCurrency? currency) async {
    if (currency == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    if (currency.id != null) {
      await prefs.setInt(_currencyIdKey, currency.id!);
    }
    if (currency.name != null) {
      await prefs.setString(_currencyNameKey, currency.name!);
    }
    if (currency.digitalCode != null) {
      await prefs.setInt(_currencyDigitalCodeKey, currency.digitalCode!);
    }
    if (currency.symbolCode != null) {
      await prefs.setString(_currencySymbolCodeKey, currency.symbolCode!);
    }

    await prefs.setString(_currencyJsonKey, jsonEncode(currency.toJson()));
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

  /// Получить currency_id
  static Future<int?> getCurrencyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currencyIdKey);
  }

  /// Получить валюту целиком из сохраненного JSON
  static Future<LocalizationCurrency?> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_currencyJsonKey);

    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> data =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return LocalizationCurrency.fromJson(data);
    } catch (_) {
      return null;
    }
  }
  
  /// Проверить применены ли настройки локализации
  static Future<bool> hasLocalizationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_languageKey) && prefs.containsKey(_dialCodeKey);
  }
}
