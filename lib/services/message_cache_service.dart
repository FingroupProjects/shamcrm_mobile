import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/offline/repositories/chat_message_cache_repository.dart';
import 'package:flutter/foundation.dart';

/// Локальный кэш истории чата на SQLite вместо SharedPreferences.
class MessageCacheService {
  MessageCacheService._({
    ChatMessageCacheRepository? repository,
  }) : _repository = repository;

  static final MessageCacheService _instance = MessageCacheService._();
  factory MessageCacheService() => _instance;

  ChatMessageCacheRepository? _repository;
  final Map<int, List<Message>> _memoryCache = {};
  final Map<int, DateTime> _memoryCacheTime = {};

  ChatMessageCacheRepository? _resolveRepository() {
    return _repository ??= ChatMessageCacheRepository.tryFromRuntime();
  }

  Future<void> cacheMessages(int chatId, List<Message> messages) async {
    try {
      final persistentMessages = messages
          .where((message) => !message.isUploading)
          .toList(growable: false);
      _memoryCache[chatId] = persistentMessages;
      _memoryCacheTime[chatId] = DateTime.now();
      final repository = _resolveRepository();
      if (repository == null) {
        debugPrint(
            'MessageCache: OfflineRuntime недоступен, сохраняем только в memory cache');
        return;
      }
      await repository.saveMessages(chatId, persistentMessages);
    } catch (e) {
      debugPrint('MessageCache: cache error for chat=$chatId: $e');
    }
  }

  Future<List<Message>?> getCachedMessages(int chatId) async {
    final memoryMessages = _memoryCache[chatId];
    final memoryTime = _memoryCacheTime[chatId];
    if (memoryMessages != null &&
        memoryTime != null &&
        DateTime.now().difference(memoryTime).inMinutes < 5) {
      return memoryMessages;
    }

    try {
      final repository = _resolveRepository();
      if (repository == null) {
        return null;
      }
      final messages = await repository.getMessages(chatId);
      if (messages.isEmpty) {
        return null;
      }
      _memoryCache[chatId] = messages;
      _memoryCacheTime[chatId] = DateTime.now();
      return messages;
    } catch (e) {
      debugPrint('MessageCache: read error for chat=$chatId: $e');
      return null;
    }
  }

  Future<bool> hasCachedMessages(int chatId) async {
    if (_memoryCache.containsKey(chatId)) {
      return true;
    }
    final repository = _resolveRepository();
    if (repository == null) {
      return false;
    }
    return repository.hasMessages(chatId);
  }

  Future<void> clearChatCache(int chatId) async {
    _memoryCache.remove(chatId);
    _memoryCacheTime.remove(chatId);
  }

  DateTime? getLastUpdateTime(int chatId) {
    return _memoryCacheTime[chatId];
  }

  Future<DateTime?> getLastUpdateTimeAsync(int chatId) async {
    return _memoryCacheTime[chatId];
  }

  Future<void> clearOldCache(
      {Duration maxAge = const Duration(days: 7)}) async {
    final expiredIds = _memoryCacheTime.entries
        .where((entry) => DateTime.now().difference(entry.value) > maxAge)
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final chatId in expiredIds) {
      _memoryCache.remove(chatId);
      _memoryCacheTime.remove(chatId);
    }
  }

  Future<void> clearAllCache() async {
    _memoryCache.clear();
    _memoryCacheTime.clear();

    try {
      final repository = _resolveRepository();
      if (repository == null) {
        return;
      }
      await repository.clearAllMessages();
    } catch (e) {
      debugPrint('MessageCache: clear all error: $e');
    }
  }
}
