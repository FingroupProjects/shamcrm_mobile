import 'dart:convert';

import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/offline/core/local_operation_status.dart';
import 'package:crm_task_manager/offline/core/offline_runtime.dart';
import 'package:crm_task_manager/offline/db/app_database.dart';
import 'package:drift/drift.dart';

class ChatMessageCacheRepository {
  ChatMessageCacheRepository(this._database);

  factory ChatMessageCacheRepository.fromRuntime() {
    return ChatMessageCacheRepository(OfflineRuntime.instance.database);
  }

  static ChatMessageCacheRepository? tryFromRuntime() {
    final runtime = OfflineRuntime.maybeInstance;
    if (runtime == null) {
      return null;
    }
    return ChatMessageCacheRepository(runtime.database);
  }

  static const int maxCachedMessages = 200;

  final AppDatabase _database;

  Future<void> saveMessages(
    int chatId,
    List<Message> messages, {
    String? chatType,
  }) async {
    final now = DateTime.now();
    await (_database.delete(_database.chatMessages)
          ..where((tbl) => tbl.chatId.equals(chatId)))
        .go();

    final sliced = messages.take(maxCachedMessages).toList(growable: false);
    await _database.batch((batch) {
      batch.insertAll(
        _database.chatMessages,
        sliced.map((message) {
          return ChatMessagesCompanion.insert(
            localId: 'server_${chatId}_${message.id}',
            chatId: chatId,
            serverMessageId: Value(message.id > 0 ? message.id : null),
            payload: jsonEncode(message.toCacheJson(chatType: chatType)),
            syncStatus: LocalOperationStatus.synced.value,
            isOutgoing: Value(message.isMyMessage),
            createdAt: now,
            updatedAt: now,
          );
        }).toList(),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<List<Message>> getMessages(int chatId, {String? chatType}) async {
    final rows = await (_database.select(_database.chatMessages)
          ..where(
              (tbl) => tbl.chatId.equals(chatId) & tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.createdAt),
          ]))
        .get();

    final messages = <Message>[];
    for (final row in rows) {
      final decoded = jsonDecode(row.payload);
      if (decoded is! Map) continue;
      final json = Map<String, dynamic>.from(decoded);
      // Старый снимок без версии рисовал чужие типы и сразу сменялся.
      if (!isDisplaySafeCachePayload(json)) continue;
      final storedType = json['chat_type']?.toString();
      if (chatType != null &&
          storedType != null &&
          storedType.isNotEmpty &&
          storedType != chatType) {
        continue;
      }
      messages.add(Message.fromJson(json, chatType: chatType));
    }
    return messages;
  }

  Future<bool> hasMessages(int chatId) async {
    final countExpression = _database.chatMessages.localId.count();
    final query = _database.selectOnly(_database.chatMessages)
      ..addColumns([countExpression])
      ..where(_database.chatMessages.chatId.equals(chatId));
    final row = await query.getSingle();
    return (row.read(countExpression) ?? 0) > 0;
  }

  Future<void> clearAllMessages() async {
    await _database.delete(_database.chatMessages).go();
  }

}
