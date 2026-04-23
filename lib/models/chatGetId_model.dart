import 'package:crm_task_manager/models/chats_model.dart';
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
      final chatUsersRaw = data['chatUsers'] as List;
      debugPrint('   chatUsers length: ${chatUsersRaw.length}');

      for (var i = 0; i < chatUsersRaw.length; i++) {
        try {
          final chatUser = ChatUser.fromJson(chatUsersRaw[i]);
          chatUsersList.add(chatUser);
          debugPrint('   ✅ Parsed chatUser[$i]: ${chatUser.participant.name}');
        } catch (e) {
          debugPrint('   ❌ Failed to parse chatUser[$i]: $e');
        }
      }
    } else if (data['user'] != null) {
      debugPrint('   Found single user object');
      final userJson = data['user'];
      final participant = Participant(
        id: userJson['id'] ?? 0,
        name: userJson['name'] ?? '',
        login: userJson['login'] ?? '',
        email: userJson['email'] ?? '',
        phone: userJson['phone'] ?? '',
        image: userJson['image'] ?? '',
        lastSeen: userJson['last_seen'],
        deletedAt: userJson['deleted_at'],
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
      String channelName = data['channel']?['name'] ?? 'telegram_account';
      name = data['integration']?['name'] ?? channelName;
      debugPrint('   ✅ Lead name: $name');
    } else if (data['type'] == 'corporate') {
      name = data['name']?.toString() ?? '';
      debugPrint('   ✅ Corporate raw name: "$name"');

      // Если name пустой, но есть group
      if (name.isEmpty && data['group'] != null) {
        name = data['group']['name'] ?? '';
        debugPrint('   ✅ Using group name: $name');
      }
    } else if (data['type'] == 'task') {
      name = data['task']?['name'] ?? '';
      debugPrint('   ✅ Task name: $name');
    } else {
      name = data['name']?.toString() ?? '';
      debugPrint('   ✅ Default name: $name');
    }

    String channelName = '';
    if (data['type'] == 'lead') {
      channelName = data['channel']?['name'] ?? 'telegram_account';
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
      id: data['id'] ?? 0,
      uniqueId: data['unique_id'] as String?,
      name: name,
      canSendMessage: data["can_send_message"] ?? false,
      type: data['type'],
      chatUsers: chatUsersList,
      group: data['group'] != null ? Group.fromJson(data['group']) : null,
      channelName: channelName,
      referralBody: data['referral_body'],
      advertising: data['advertising'] != null
          ? ChatAdvertising.fromJson(
              Map<String, dynamic>.from(data['advertising'] as Map),
            )
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
      id: json['id'] ?? 0,
      externalAdId: json['external_ad_id']?.toString(),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
      source: json['source']?.toString(),
      status: json['status']?.toString(),
      cost: json['cost'] as num?,
      description: json['description']?.toString(),
      mediaUrl: json['media_url']?.toString(),
      postId: json['post_id']?.toString(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
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
      type: json['type'] ?? '',
      participant: json['participant'] != null
          ? Participant.fromJson(json['participant'])
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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      login: json['login'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      image: json['image'] ?? '',
      lastSeen: json['last_seen'],
      deletedAt: json['deleted_at'],
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
