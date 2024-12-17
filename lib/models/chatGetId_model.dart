import 'package:crm_task_manager/models/chats_model.dart';

class ChatsGetId {
  final int id;
  final String name;
  final bool canSendMessage;
  final String? type;
  final List<ChatUser> chatUsers;
  final Group? group; // Добавляем поле group

  ChatsGetId({
    required this.id,
    required this.name,
    required this.canSendMessage,
    this.type,
    required this.chatUsers,
    this.group,
  });

  factory ChatsGetId.fromJson(Map<String, dynamic> json) {
    final data = json['result'];
    if (data == null) {
      throw Exception("Ответ не содержит поля 'result'");
    }
    var chatUsersList = (data['chatUsers'] as List)
        .map((chatUserJson) => ChatUser.fromJson(chatUserJson))
        .toList();

    return ChatsGetId(
      id: data['id'] ?? 0,
      name: data['lead'] != null
          ? data['lead']['name'] ?? 'Без имени'
          : '',
      canSendMessage: data["can_send_message"] ?? false,
      type: data['type'],
      chatUsers: chatUsersList,
      group: data['group'] != null ? Group.fromJson(data['group']) : null, // Парсинг group
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
      participant: Participant.fromJson(json['participant']),
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
}

