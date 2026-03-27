import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Map<String, String> _localizedStrings = {};

  Future<bool> load() async {
  try {
    String jsonString = await rootBundle.loadString('assets/langs/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  } catch (e) {
    print("Ошибка загрузки локализации: $e");
    return false;
  }
}
  String translate(String key) {
    return _localizedStrings[key] ?? key;
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

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
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