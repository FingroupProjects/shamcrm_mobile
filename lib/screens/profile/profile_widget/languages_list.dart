import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

 static AppLocalizations of(BuildContext context) {
  final result = Localizations.of<AppLocalizations>(context, AppLocalizations);
  print('Current locale: ${result?.locale}');
  return result!;
}

    static const _localizedValues = {
    'ru': {
      'Дашборд': 'Дашборд',
      'Задачи': 'Задачи',
      'Лиды': 'Лиды',
      'Чаты': 'Чаты',
      'Сделки': 'Сделки',
      'Язык': 'Язык',
      'Закрыть': 'Закрыть',
      'Выберите язык': 'Выберите язык',
      'Русский': 'Русский',
      'Узбекский': 'Узбекский',
      'Английский': 'Английский',
    },
    'uz': {
      'Дашборд': 'Boshqaruv paneli',
      'Задачи': 'Vazifalar',
      'Лиды': 'Lidlar',
      'Чаты': 'Chatlar',
      'Сделки': 'Bitimlar',
      'Язык': 'Til',
      'Закрыть': 'Yopish',
      'Выберите язык': 'Tilni tanlang',
      'Русский': 'Rus tili',
      'Узбекский': 'O\'zbek tili',
      'Английский': 'Ingliz tili',
    },
    'en': {
      'Дашборд': 'Dashboard',
      'Задачи': 'Tasks',
      'Лиды': 'Leads',
      'Чаты': 'Chats',
      'Сделки': 'Deals',
      'Язык': 'Language',
      'Закрыть': 'Close',
      'Выберите язык': 'Select Language',
      'Русский': 'Russian',
      'Узбекский': 'Uzbek',
      'Английский': 'English',
    },
  };


  String get dashboard => _localizedValues[locale.languageCode]!['Дашборд']!;
  String get tasks => _localizedValues[locale.languageCode]!['Задачи']!;
  String get leads => _localizedValues[locale.languageCode]!['Лиды']!;
  String get chats => _localizedValues[locale.languageCode]!['Чаты']!;
  String get deals => _localizedValues[locale.languageCode]!['Сделки']!;
  String get language => _localizedValues[locale.languageCode]!['Язык']!;
  String get close => _localizedValues[locale.languageCode]!['Закрыть']!;
  String get selectLanguage => _localizedValues[locale.languageCode]!['Выберите язык']!;
  String get russian => _localizedValues[locale.languageCode]!['Русский']!;
  String get uzbek => _localizedValues[locale.languageCode]!['Узбекский']!;
  String get english => _localizedValues[locale.languageCode]!['Английский']!;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}