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
  } 
  else if (data['user'] != null) {
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
  } 
  else if (data['type'] == 'corporate') {
    name = data['name']?.toString() ?? '';
    debugPrint('   ✅ Corporate raw name: "$name"');
    
    // Если name пустой, но есть group
    if (name.isEmpty && data['group'] != null) {
      name = data['group']['name'] ?? '';
      debugPrint('   ✅ Using group name: $name');
    }
  } 
  else if (data['type'] == 'task') {
    name = data['task']?['name'] ?? '';
    debugPrint('   ✅ Task name: $name');
  } 
  else {
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
  debugPrint('   group: ${data['group'] != null ? data['group']['name'] : 'null'}');
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
  );
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