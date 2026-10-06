import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Помнит колонку только пока этот запуск приложения жив.
/// Reload, перезапуск и выход начинают с первой колонки.
class SectionTabMemory {
  SectionTabMemory._();

  static int _epoch = 0;
  static final Map<String, String> _values = {};

  /// Меняется, когда колонку нужно забыть.
  static final ValueNotifier<int> resetTick = ValueNotifier<int>(0);

  static int get epoch => _epoch;

  static Future<void> save(String section, String value) async {
    final epoch = _epoch;
    if (epoch != _epoch) return;
    _values[section] = value;
  }

  static Future<String?> read(String section) async {
    return _values[section];
  }

  /// Стирает колонку в памяти и старые записи с диска.
  static Future<void> clearAll() async {
    _epoch++;
    _values.clear();
    resetTick.value = _epoch;
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('section_tab_'))
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
