import 'package:flutter/material.dart';

class LocaleManager with ChangeNotifier {
  static final LocaleManager _instance = LocaleManager._internal();

  factory LocaleManager() {
    return _instance;
  }

  LocaleManager._internal();

  Locale _currentLocale = const Locale('ru');

  Locale get currentLocale => _currentLocale;

  void setLocale(Locale locale) {
    if (_currentLocale != locale) {
      _currentLocale = locale;
      notifyListeners();
    }
  }
}
