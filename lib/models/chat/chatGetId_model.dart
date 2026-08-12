import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:flutter/material.dart';

class ChatsGetId {
  final int id;
  final String? uniqueId;
  final String name;
  final bool canSendMessage;
  final String? type;
  final List<ChatUser> chatUsers;
  final Group? group;
  final String channelName;
  final String? referralBody;
  final ChatAdvertising? advertising;

  ChatsGetId({
    required this.id,
    this.uniqueId,
    required this.name,
    required this.canSendMessage,
    this.type,
    required this.chatUsers,
    this.group,
    required this.channelName,
    this.referralBody,
    this.advertising,
  });

  factory ChatsGetId.fromJson(Map<String, dynamic> json) {
    debugPrint('════════════════════════════════════════════════════════');
    debugPrint('🔧 [ChatsGetId.fromJson] Starting parsing...');
    debugPrint('🔧 [ChatsGetId.fromJson] JSON keys: ${json.keys.toList()}');

    final data = json;
    if (data == null) {
      throw Exception("Ответ не содержит данных");
    }

    // ✅ ОБРАБОТКА chatUsers
    List<ChatUser> chatUsersList = [];

    debugPrint('🔧 [ChatsGetId.fromJson] Checking chatUsers...');
    debugPrint('   chatUsers exists: ${data['chatUsers'] != null}');
    debugPrint('   chatUsers type: ${data['chatUsers']?.runtimeType}');

    if (data['chatUsers'] != null && data['chatUsers'] is List) {
      final chatUsersRaw = SafeConverters.toList(data['chatUsers']);
      debugPrint('   chatUsers length: ${chatUsersRaw.length}');

      for (var i = 0; i < chatUsersRaw.length; i++) {
        try {
          final chatUser =
              ChatUser.fromJson(SafeConverters.toMap(chatUsersRaw[i]));
          chatUsersList.add(chatUser);
          debugPrint('   ✅ Parsed chatUser[$i]: ${chatUser.participant.name}');
        } catch (e) {
          debugPrint('   ❌ Failed to parse chatUser[$i]: $e');
        }
      }
    } else if (data['user'] != null) {
      debugPrint('   Found single user object');
      final userJson = SafeConverters.toMap(data['user']);
      final participant = Participant(
        id: SafeConverters.toInt(userJson['id']),
        name: SafeConverters.toSafeString(userJson['name']),
        login: SafeConverters.toSafeString(userJson['login']),
        email: SafeConverters.toSafeString(userJson['email']),
        phone: SafeConverters.toSafeString(userJson['phone']),
        image: SafeConverters.toSafeString(userJson['image']),
        lastSeen: SafeConverters.toStringOrNull(userJson['last_seen']),
        deletedAt: SafeConverters.toStringOrNull(userJson['deleted_at']),
      );
      chatUsersList = [
        ChatUser(
          type: 'user',
          participant: participant,
        )
      ];
      debugPrint('   ✅ Created chatUser from single user: ${participant.name}');
    } else {
      debugPrint('   ⚠️ No chatUsers or user found');
    }

    // ✅ ОБРАБОТКА name
    String name = '';

    debugPrint('🔧 [ChatsGetId.fromJson] Determining name...');
    debugPrint('   type: ${data['type']}');
    debugPrint('   raw name: "${data['name']}"');
    debugPrint('   group: ${data['group']}');

    if (data['type'] == 'lead') {
      final channelMap = SafeConverters.toMapOrNull(data['channel']);
      String channelName = SafeConverters.toSafeString(
        channelMap?['name'],
        defaultValue: 'telegram_account',
      );
      final integrationMap = SafeConverters.toMapOrNull(data['integration']);
      name = SafeConverters.toSafeString(integrationMap?['name'], defaultValue: channelName);
      debugPrint('   ✅ Lead name: $name');
    } else if (data['type'] == 'corporate') {
      name = SafeConverters.toSafeString(data['name']);
      debugPrint('   ✅ Corporate raw name: "$name"');

      if (name.isEmpty && data['group'] != null) {
        name = SafeConverters.toSafeString(SafeConverters.toMap(data['group'])['name']);
        debugPrint('   ✅ Using group name: $name');
      }
    } else if (data['type'] == 'task') {
      name = SafeConverters.toSafeString(SafeConverters.toMapOrNull(data['task'])?['name']);
      debugPrint('   ✅ Task name: $name');
    } else {
      name = SafeConverters.toSafeString(data['name']);
      debugPrint('   ✅ Default name: $name');
    }

    String channelName = '';
    if (data['type'] == 'lead') {
      channelName = SafeConverters.toSafeString(
        SafeConverters.toMapOrNull(data['channel'])?['name'],
        defaultValue: 'telegram_account',
      );
    }

    debugPrint('🔧 [ChatsGetId.fromJson] Final values:');
    debugPrint('   id: ${data['id']}');
    debugPrint('   name: "$name"');
    debugPrint('   type: ${data['type']}');
    debugPrint('   chatUsers.length: ${chatUsersList.length}');
    debugPrint(
        '   group: ${data['group'] != null ? data['group']['name'] : 'null'}');
    debugPrint('════════════════════════════════════════════════════════');

    return ChatsGetId(
      id: SafeConverters.toInt(data['id']),
      uniqueId: SafeConverters.toStringOrNull(data['unique_id']),
      name: name,
      canSendMessage: SafeConverters.toBool(data['can_send_message']),
      type: SafeConverters.toStringOrNull(data['type']),
      chatUsers: chatUsersList,
      group: SafeConverters.toMapOrNull(data['group']) != null
          ? Group.fromJson(SafeConverters.toMap(data['group']))
          : null,
      channelName: channelName,
      referralBody: SafeConverters.toStringOrNull(data['referral_body']),
      advertising: SafeConverters.toMapOrNull(data['advertising']) != null
          ? ChatAdvertising.fromJson(SafeConverters.toMap(data['advertising']))
          : null,
    );
  }
}

class ChatAdvertising {
  final int id;
  final String? externalAdId;
  final String name;
  final String? type;
  final String? source;
  final String? status;
  final num? cost;
  final String? description;
  final String? mediaUrl;
  final String? postId;
  final Map<String, dynamic>? metadata;
  final String? createdAt;
  final String? updatedAt;

  ChatAdvertising({
    required this.id,
    required this.name,
    this.externalAdId,
    this.type,
    this.source,
    this.status,
    this.cost,
    this.description,
    this.mediaUrl,
    this.postId,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatAdvertising.fromJson(Map<String, dynamic> json) {
    return ChatAdvertising(
      id: SafeConverters.toInt(json['id']),
      externalAdId: SafeConverters.toStringOrNull(json['external_ad_id']),
      name: SafeConverters.toSafeString(json['name']),
      type: SafeConverters.toStringOrNull(json['type']),
      source: SafeConverters.toStringOrNull(json['source']),
      status: SafeConverters.toStringOrNull(json['status']),
      cost: SafeConverters.toNumOrNull(json['cost']),
      description: SafeConverters.toStringOrNull(json['description']),
      mediaUrl: SafeConverters.toStringOrNull(json['media_url']),
      postId: SafeConverters.toStringOrNull(json['post_id']),
      metadata: SafeConverters.toMapOrNull(json['metadata']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
    );
  }

  String? get primaryUrl {
    final media = mediaUrl?.trim();
    if (media != null && media.isNotEmpty) {
      return media;
    }

    final post = postId?.trim();
    if (post != null && post.isNotEmpty) {
      return post;
    }

    return null;
  }
}

class ChatUser {
  final String type;
  final Participant participant;

  ChatUser({
    required this.type,
    required this.participant,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      type: SafeConverters.toSafeString(json['type']),
      participant: SafeConverters.toMapOrNull(json['participant']) != null
          ? Participant.fromJson(SafeConverters.toMap(json['participant']))
          : Participant.empty(),
    );
  }
}

class Participant {
  final int id;
  final String name;
  final String login;
  final String email;
  final String phone;
  final String image;
  final String? lastSeen;
  final String? deletedAt;

  Participant({
    required this.id,
    required this.name,
    required this.login,
    required this.email,
    required this.phone,
    required this.image,
    this.lastSeen,
    this.deletedAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      login: SafeConverters.toSafeString(json['login']),
      email: SafeConverters.toSafeString(json['email']),
      phone: SafeConverters.toSafeString(json['phone']),
      image: SafeConverters.toSafeString(json['image']),
      lastSeen: SafeConverters.toStringOrNull(json['last_seen']),
      deletedAt: SafeConverters.toStringOrNull(json['deleted_at']),
    );
  }

  static Participant empty() {
    return Participant(
      id: 0,
      name: 'Удаленный аккаунт',
      login: '',
      email: '',
      phone: '',
      image: '',
      lastSeen: null,
      deletedAt: null,
    );
  }
}
