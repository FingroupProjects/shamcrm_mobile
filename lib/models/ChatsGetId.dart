import 'package:crm_task_manager/models/chats_model.dart';

class ChatsGetId {
  final int id;
  final Channel? channel;
  final Group? group;
  final ChatUser? user;
  final bool canSendMessage;
  final String type;
  final int unreadCount;
  final String? referralBody;
  final Integration? integration;

  ChatsGetId({
    required this.id,
    this.channel,
    this.group,
    this.user,
    required this.canSendMessage,
    required this.type,
    required this.unreadCount,
    this.referralBody,
    this.integration,
  });

  factory ChatsGetId.fromJson(Map<String, dynamic> json) {
    // Теперь json - это уже 'result'
    return ChatsGetId(
      id: json['id'] ?? 0,
      channel: json['channel'] != null ? Channel.fromJson(json['channel']) : null,
      group: json['group'] != null ? Group.fromJson(json['group']) : null,
      user: json['user'] != null ? ChatUser.fromJson({'participant': json['user']}) : null,
      canSendMessage: json['can_send_message'] ?? false,
      type: json['type'] ?? '',
      unreadCount: json['unread_count'] ?? 0,
      referralBody: json['referral_body'],
      integration: json['integration'] != null ? Integration.fromJson(json['integration']) : null,
    );
  }
}

class Channel {
  final int id;
  final String name;
  final int? organizationId;

  Channel({
    required this.id,
    required this.name,
    this.organizationId,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      organizationId: json['organization_id'],
    );
  }
}

class Integration {
  final int id;
  final String name;
  final String username;

  Integration({
    required this.id,
    required this.name,
    required this.username,
  });

  factory Integration.fromJson(Map<String, dynamic> json) {
    return Integration(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
    );
  }
}

// Минимальные классы на основе использования (не трогаем другие файлы)
class Group {
  // Добавьте поля по необходимости, если извест nы
  Group.fromJson(Map<String, dynamic> json);
}

class ChatUser {
  final String type;
  final Participant participant;
  final List<ChatUser> chatUsers = []; // Если нужно для других мест

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