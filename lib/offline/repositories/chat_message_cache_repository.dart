import 'dart:convert';

import 'package:crm_task_manager/models/chats_model.dart';
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

  Future<void> saveMessages(int chatId, List<Message> messages) async {
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
            payload: jsonEncode(_messageToJson(message)),
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

  Future<List<Message>> getMessages(int chatId) async {
    final rows = await (_database.select(_database.chatMessages)
          ..where(
              (tbl) => tbl.chatId.equals(chatId) & tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.createdAt),
          ]))
        .get();

    return rows
        .map((row) => Message.fromJson(
              jsonDecode(row.payload) as Map<String, dynamic>,
            ))
        .toList(growable: false);
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

  Map<String, dynamic> _messageToJson(Message message) {
    return {
      'id': message.id,
      'text': message.text,
      'type': message.type,
      'file_path': message.filePath,
      'is_my_message': message.isMyMessage,
      'created_at': message.createMessateTime,
      'sender': {'name': message.senderName},
      'voice_duration': message.duration.inSeconds,
      'is_pinned': message.isPinned,
      'is_changed': message.isChanged,
      'is_read': message.isRead,
      'is_note': message.isNote,
      'local_delivery_status': message.deliveryStatus.name,
      'local_reply_message_id': message.localReplyMessageId,
      'local_response_type': message.localResponseType,
      'forwarded_message': message.forwardedMessage != null
          ? {
              'id': message.forwardedMessage!.id,
              'text': message.forwardedMessage!.text,
              'type': message.forwardedMessage!.type,
              'sender': {'name': message.forwardedMessage!.senderName},
            }
          : null,
    };
  }
}
