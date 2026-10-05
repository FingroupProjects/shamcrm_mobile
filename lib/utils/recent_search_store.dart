import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Последние запросы поиска раздела. Хранятся на этом телефоне.
class RecentSearchStore {
  RecentSearchStore._();

  static const int _limit = 5;

  static Future<List<String>> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('recent_search_$key');
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
  }

  static Future<void> remember(String key, String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return;
    final current = await read(key);
    final next = [
      trimmed,
      ...current.where((item) => item.toLowerCase() != trimmed.toLowerCase()),
    ];
    if (next.length > _limit) {
      next.removeRange(_limit, next.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recent_search_$key', jsonEncode(next));
  }
}
