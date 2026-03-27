import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/models/chats_model.dart';

/// ✅ Сервис для кэширования сообщений в SharedPreferences
/// Используется для мгновенной загрузки чатов (как в Telegram)
/// Кэширует последние сообщения для каждого чата
class MessageCacheService {
  static const String _cacheKeyPrefix = 'cached_messages_chat_';
  static const String _metaKeyPrefix = 'cache_meta_chat_';
  static const int _maxCachedMessages = 50; // Максимум сообщений в кэше (для экономии памяти)
  
  static final MessageCacheService _instance = MessageCacheService._internal();
  factory MessageCacheService() => _instance;
  MessageCacheService._internal();

  // ✅ Кэш в памяти для быстрого доступа (избегаем чтения SharedPreferences каждый раз)
  final Map<int, List<Message>> _memoryCache = {};
  final Map<int, DateTime> _memoryCacheTime = {};

  /// ✅ Сохранить сообщения в кэш (и в память, и в SharedPreferences)
  Future<void> cacheMessages(int chatId, List<Message> messages) async {
    try {
      // ✅ Ограничиваем количество кэшируемых сообщений (берем последние)
      final messagesToCache = messages.length > _maxCachedMessages
          ? messages.take(_maxCachedMessages).toList()
          : messages;

      // ✅ Сохраняем в память для мгновенного доступа
      _memoryCache[chatId] = messagesToCache;
      _memoryCacheTime[chatId] = DateTime.now();

      // ✅ Сохраняем в SharedPreferences для персистентности
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messagesToCache.map((msg) => _messageToJson(msg)).toList();
      final cacheKey = '$_cacheKeyPrefix$chatId';
      final metaKey = '$_metaKeyPrefix$chatId';

      await prefs.setString(cacheKey, json.encode(messagesJson));
      await prefs.setString(metaKey, DateTime.now().toIso8601String());

      debugPrint('✅ MessageCache: Cached ${messagesToCache.length} messages for chat $chatId');
    } catch (e) {
      debugPrint('❌ MessageCache: Error caching messages for chat $chatId: $e');
    }
  }

  /// ✅ Получить кэшированные сообщения (сначала из памяти, потом из SharedPreferences)
  Future<List<Message>?> getCachedMessages(int chatId) async {
    try {
      // ✅ Сначала проверяем кэш в памяти (быстрее)
      if (_memoryCache.containsKey(chatId)) {
        final cachedTime = _memoryCacheTime[chatId];
        if (cachedTime != null) {
          final age = DateTime.now().difference(cachedTime);
          // Если кэш в памяти свежий (менее 5 минут), используем его
          if (age.inMinutes < 5) {
            debugPrint('✅ MessageCache: Retrieved ${_memoryCache[chatId]!.length} messages from MEMORY cache for chat $chatId');
            return _memoryCache[chatId]!;
          }
        }
      }

      // ✅ Если нет в памяти или устарел, загружаем из SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$chatId';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson == null || cachedJson.isEmpty) {
        debugPrint('⚠️ MessageCache: No cached messages for chat $chatId');
        return null;
      }

      final List<dynamic> messagesList = json.decode(cachedJson);
      final messages = messagesList.map((json) => _messageFromJson(json)).toList();

      // ✅ Восстанавливаем в память
      _memoryCache[chatId] = messages;
      _memoryCacheTime[chatId] = DateTime.now();

      debugPrint('✅ MessageCache: Retrieved ${messages.length} messages from PERSISTENT cache for chat $chatId');
      return messages;

    } catch (e) {
      debugPrint('❌ MessageCache: Error getting cached messages for chat $chatId: $e');
      return null;
    }
  }

  /// ✅ Проверить, есть ли кэш для чата
  Future<bool> hasCachedMessages(int chatId) async {
    // Сначала проверяем память
    if (_memoryCache.containsKey(chatId)) {
      return true;
    }

    // Затем проверяем SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$chatId';
      return prefs.containsKey(cacheKey);
    } catch (e) {
      return false;
    }
  }

  /// ✅ Очистить кэш конкретного чата
  Future<void> clearChatCache(int chatId) async {
    try {
      // Очищаем из памяти
      _memoryCache.remove(chatId);
      _memoryCacheTime.remove(chatId);

      // Очищаем из SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$chatId';
      final metaKey = '$_metaKeyPrefix$chatId';
      await prefs.remove(cacheKey);
      await prefs.remove(metaKey);

      debugPrint('🗑️ MessageCache: Cleared cache for chat $chatId');
    } catch (e) {
      debugPrint('❌ MessageCache: Error clearing cache for chat $chatId: $e');
    }
  }

  /// ✅ Получить время последнего обновления кэша (только из памяти, для скорости)
  DateTime? getLastUpdateTime(int chatId) {
    // Проверяем только память (быстро, без async)
    return _memoryCacheTime[chatId];
  }

  /// ✅ Получить время последнего обновления из SharedPreferences (async версия)
  Future<DateTime?> getLastUpdateTimeAsync(int chatId) async {
    // Сначала проверяем память
    if (_memoryCacheTime.containsKey(chatId)) {
      return _memoryCacheTime[chatId];
    }

    // Затем проверяем SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final metaKey = '$_metaKeyPrefix$chatId';
      final timestamp = prefs.getString(metaKey);
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      return null;
    }
  }

  /// ✅ Конвертация Message в JSON для сохранения
  Map<String, dynamic> _messageToJson(Message message) {
    return {
      'id': message.id,
      'text': message.text,
      'type': message.type,
      'filePath': message.filePath,
      'isMyMessage': message.isMyMessage,
      'createMessateTime': message.createMessateTime,
      'senderName': message.senderName,
      'duration': message.duration.inSeconds,
      'isPinned': message.isPinned,
      'isChanged': message.isChanged,
      'isRead': message.isRead,
      'isNote': message.isNote,
      'forwardedMessage': message.forwardedMessage != null
          ? {
              'id': message.forwardedMessage!.id,
              'text': message.forwardedMessage!.text,
              'type': message.forwardedMessage!.type,
              'senderName': message.forwardedMessage!.senderName,
            }
          : null,
    };
  }

  /// ✅ Конвертация JSON в Message для загрузки
  Message _messageFromJson(Map<String, dynamic> json) {
    ForwardedMessage? forwardedMessage;
    if (json['forwardedMessage'] != null) {
      final fm = json['forwardedMessage'] as Map<String, dynamic>;
      forwardedMessage = ForwardedMessage(
        id: fm['id'] ?? 0,
        text: fm['text'] ?? '',
        type: fm['type'] ?? '',
        senderName: fm['senderName'],
      );
    }

    return Message(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      type: json['type'] ?? '',
      filePath: json['filePath'],
      isMyMessage: json['isMyMessage'] ?? false,
      createMessateTime: json['createMessateTime'] ?? '',
      senderName: json['senderName'] ?? 'Без имени',
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : const Duration(),
      isPinned: json['isPinned'] ?? false,
      isChanged: json['isChanged'] ?? false,
      isRead: json['isRead'] ?? false,
      isNote: json['isNote'] ?? false,
      forwardedMessage: forwardedMessage,
    );
  }

  /// ✅ Очистка старого кэша (вызывать периодически или при нехватке места)
  Future<void> clearOldCache({Duration maxAge = const Duration(days: 7)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final now = DateTime.now();

      int clearedCount = 0;
      for (final key in allKeys) {
        if (key.startsWith(_metaKeyPrefix)) {
          final timestampStr = prefs.getString(key);
          if (timestampStr != null) {
            try {
              final timestamp = DateTime.parse(timestampStr);
              if (now.difference(timestamp) > maxAge) {
                // Удаляем старый кэш
                final chatId = key.replaceFirst(_metaKeyPrefix, '');
                await clearChatCache(int.tryParse(chatId) ?? 0);
                clearedCount++;
              }
            } catch (e) {
              // Если не удалось распарсить, удаляем
              await prefs.remove(key);
            }
          }
        }
      }

      debugPrint('🧹 MessageCache: Cleared $clearedCount old cache entries');
    } catch (e) {
      debugPrint('❌ MessageCache: Error clearing old cache: $e');
    }
  }
}

