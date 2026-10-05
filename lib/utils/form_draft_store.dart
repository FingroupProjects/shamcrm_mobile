import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Черновик формы на этом телефоне: лид, сделка или документ.
class FormDraftStore {
  FormDraftStore._();

  static final FormDraftStore instance = FormDraftStore._();

  Future<Map<String, String>> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('form_draft_$key');
    if (raw == null || raw.isEmpty) return const {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const {};
    return decoded.map((entryKey, value) => MapEntry(entryKey.toString(), value.toString()));
  }

  Future<void> save(String key, Map<String, String> fields) async {
    final cleaned = <String, String>{};
    fields.forEach((field, value) {
      if (value.trim().isNotEmpty) cleaned[field] = value;
    });
    final prefs = await SharedPreferences.getInstance();
    if (cleaned.isEmpty) {
      await prefs.remove('form_draft_$key');
      return;
    }
    await prefs.setString('form_draft_$key', jsonEncode(cleaned));
  }

  Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('form_draft_$key');
  }
}
