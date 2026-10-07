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
  final Map<String, List<Message>> _memoryCache = {};
  final Map<String, DateTime> _memoryCacheTime = {};

  String _cacheKey(int chatId, String? chatType) => '${chatType ?? ''}|$chatId';

  ChatMessageCacheRepository? _resolveRepository() {
    return _repository ??= ChatMessageCacheRepository.tryFromRuntime();
  }

  Future<void> cacheMessages(
    int chatId,
    List<Message> messages, {
    String? chatType,
  }) async {
    try {
      final persistentMessages = messages
          .where((message) => !message.isUploading)
          .toList(growable: false);
      final key = _cacheKey(chatId, chatType);
      _memoryCache[key] = persistentMessages;
      _memoryCacheTime[key] = DateTime.now();
      final repository = _resolveRepository();
      if (repository == null) {
        debugPrint(
            'MessageCache: OfflineRuntime недоступен, сохраняем только в memory cache');
        return;
      }
      await repository.saveMessages(
        chatId,
        persistentMessages,
        chatType: chatType,
      );
    } catch (e) {
      debugPrint('MessageCache: cache error for chat=$chatId: $e');
    }
  }

  Future<List<Message>?> getCachedMessages(
    int chatId, {
    String? chatType,
  }) async {
    final key = _cacheKey(chatId, chatType);
    final memoryMessages = _memoryCache[key];
    final memoryTime = _memoryCacheTime[key];
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
      final messages = await repository.getMessages(chatId, chatType: chatType);
      if (messages.isEmpty) {
        return null;
      }
      _memoryCache[key] = messages;
      _memoryCacheTime[key] = DateTime.now();
      return messages;
    } catch (e) {
      debugPrint('MessageCache: read error for chat=$chatId: $e');
      return null;
    }
  }

  Future<bool> hasCachedMessages(int chatId, {String? chatType}) async {
    if (_memoryCache.containsKey(_cacheKey(chatId, chatType))) {
      return true;
    }
    final repository = _resolveRepository();
    if (repository == null) {
      return false;
    }
    return repository.hasMessages(chatId);
  }

  Future<void> clearChatCache(int chatId, {String? chatType}) async {
    final key = _cacheKey(chatId, chatType);
    _memoryCache.remove(key);
    _memoryCacheTime.remove(key);
  }

  Future<void> markChatMessagesRead(int chatId, {String? chatType}) async {
    try {
      final key = _cacheKey(chatId, chatType);
      List<Message>? messages = _memoryCache[key];
      messages ??= await getCachedMessages(chatId, chatType: chatType);
      if (messages == null || messages.isEmpty) {
        return;
      }

      final updated = messages
          .map((message) =>
              message.isRead ? message : message.copyWith(isRead: true))
          .toList(growable: false);
      await cacheMessages(chatId, updated, chatType: chatType);
    } catch (e) {
      debugPrint('MessageCache: mark read error for chat=$chatId: $e');
    }
  }

  DateTime? getLastUpdateTime(int chatId, {String? chatType}) {
    return _memoryCacheTime[_cacheKey(chatId, chatType)];
  }

  Future<DateTime?> getLastUpdateTimeAsync(int chatId, {String? chatType}) async {
    return _memoryCacheTime[_cacheKey(chatId, chatType)];
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
