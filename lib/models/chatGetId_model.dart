import 'package:crm_task_manager/models/chats_model.dart';

class ChatsGetId {
  final int id;
  final String name;
  final bool canSendMessage;
  final String? type;
  final List<ChatUser> chatUsers;
  final Group? group;
  final String channelName;
  final String? referralBody; // Добавлено: referral_body из JSON

  ChatsGetId({
    required this.id,
    required this.name,
    required this.canSendMessage,
    this.type,
    required this.chatUsers,
    this.group,
    required this.channelName,
    this.referralBody,
  });

  factory ChatsGetId.fromJson(Map<String, dynamic> json) {
    final data = json;
    if (data == null) {
      throw Exception("Ответ не содержит данных");
    }

    List<ChatUser> chatUsersList = [];
    if (data['user'] != null) {
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
    }

    String name = '';
    String channelName = '';
    if (data['type'] == 'lead') {
      channelName = data['channel']?['name'] ?? 'telegram_account';
      name = data['integration']?['name'] ?? channelName;
    }

    return ChatsGetId(
      id: data['id'] ?? 0,
      name: name,
      canSendMessage: data["can_send_message"] ?? false,
      type: data['type'],
      chatUsers: chatUsersList,
      group: data['group'] != null ? Group.fromJson(data['group']) : null,
      channelName: channelName,
      referralBody: data['referral_body'], // Парсим как есть
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

