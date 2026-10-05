import 'package:shared_preferences/shared_preferences.dart';

/// Помнит последнюю открытую колонку: статус лида, сделки, задачи или день события.
class SectionTabMemory {
  SectionTabMemory._();

  static String _key(String section) => 'section_tab_$section';

  static Future<void> save(String section, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(section), value);
  }

  static Future<String?> read(String section) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(section));
  }
}
