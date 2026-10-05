import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Недописанный текст чата. Живёт на телефоне, пока сообщение не отправили.
class ChatDraftStore extends ChangeNotifier {
  ChatDraftStore._();

  static final ChatDraftStore instance = ChatDraftStore._();
  static const String _prefsKey = 'chat_drafts_v1';

  final Map<int, String> _drafts = {};
  Future<void>? _loading;

  String? peek(int chatId) {
    final text = _drafts[chatId];
    if (text == null || text.trim().isEmpty) return null;
    return text;
  }

  Future<void> ensureLoaded() {
    return _loading ??= _load();
  }

  Future<void> save(int chatId, String text) async {
    await ensureLoaded();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      if (_drafts.remove(chatId) == null) return;
    } else {
      if (_drafts[chatId] == text) return;
      _drafts[chatId] = text;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> clear(int chatId) async {
    await save(chatId, '');
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      decoded.forEach((key, value) {
        final id = int.tryParse(key.toString());
        final text = value?.toString() ?? '';
        if (id == null || text.trim().isEmpty) return;
        _drafts[id] = text;
      });
      notifyListeners();
    } catch (error) {
      debugPrint('ChatDraftStore load error: $error');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode({
        for (final entry in _drafts.entries) '${entry.key}': entry.value,
      });
      await prefs.setString(_prefsKey, encoded);
    } catch (error) {
      debugPrint('ChatDraftStore save error: $error');
    }
  }
}
