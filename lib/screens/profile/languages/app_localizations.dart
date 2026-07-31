import 'dart:convert';
import 'package:crm_task_manager/utils/utf16_sanitizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  static const String _defaultLanguageCode = 'ru';
  static const List<String> _fallbackLanguageCodes = ['ru', 'en', 'uz'];
  static final Map<String, Map<String, String>> _localeCache = {};
  static final Map<String, String> _russianValueToKey = {};

  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String> _localizedStrings = {};

  Future<bool> load() async {
    try {
      _localizedStrings = await _loadLocaleMap(locale.languageCode);
      for (final languageCode in _fallbackLanguageCodes) {
        await _loadLocaleMap(languageCode);
      }

      if (_russianValueToKey.isEmpty) {
        final russianStrings = await _loadLocaleMap(_defaultLanguageCode);
        for (final entry in russianStrings.entries) {
          final normalizedValue = _normalizeLookup(entry.value);
          if (normalizedValue.isEmpty) continue;
          _russianValueToKey.putIfAbsent(normalizedValue, () => entry.key);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Ошибка загрузки локализации: $e');
      return false;
    }
  }

  static Future<Map<String, String>> _loadLocaleMap(String languageCode) async {
    final cached = _localeCache[languageCode];
    if (cached != null) return cached;

    final jsonString =
        await rootBundle.loadString('assets/langs/$languageCode.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    final localizedStrings = jsonMap.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    _localeCache[languageCode] = localizedStrings;
    return localizedStrings;
  }

  static String _normalizeLookup(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String translate(String keyOrRussianSource) {
    final directValue = _lookupByKey(keyOrRussianSource);
    if (directValue != null) return sanitizeUtf16(directValue);

    final normalizedSource = _normalizeLookup(keyOrRussianSource);
    final mappedKey = _russianValueToKey[normalizedSource];
    if (mappedKey != null) {
      final translatedValue = _lookupByKey(mappedKey);
      if (translatedValue != null) return sanitizeUtf16(translatedValue);
    }

    return sanitizeUtf16(_humanizeKey(keyOrRussianSource));
  }

  String? _lookupByKey(String key) {
    final directValue = _localizedStrings[key];
    if (directValue != null && directValue.isNotEmpty) {
      return directValue;
    }

    for (final languageCode in _fallbackLanguageCodes) {
      final fallbackMap = _localeCache[languageCode];
      if (fallbackMap == null) continue;
      final fallbackValue = fallbackMap[key];
      if (fallbackValue != null && fallbackValue.isNotEmpty) {
        return fallbackValue;
      }
    }

    return null;
  }

  String _humanizeKey(String value) {
    if (!value.contains('_')) return value;

    final words = value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');

    return words.isEmpty ? value : words;
  }

  String get dashboard => translate('dashboard');
  String get tasks => translate('tasks');
  String get leads => translate('leads');
  String get chats => translate('chats');
  String get deals => translate('deals');
  String get language => translate('language');
  String get close => translate('close');
  String get selectLanguage => translate('selectLanguage');
  String get russian => translate('russian');
  String get uzbek => translate('uzbek');
  String get english => translate('english');
  String get exit => translate('exit_account');
  String get urgent => translate('urgent');
  String get important => translate('important');
  String get normal => translate('normal');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ru', 'uz'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
