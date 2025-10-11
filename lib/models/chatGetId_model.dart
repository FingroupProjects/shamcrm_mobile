
import 'package:crm_task_manager/models/chats_model.dart';

class ChatsGetId {
  final int id;
  final String name;
  final bool canSendMessage;
  final String? type;
  final List<ChatUser> chatUsers;
  final Group? group;
  final String channelName; // Добавлено для channel.name (telegram_account и т.д.)

  ChatsGetId({
    required this.id,
    required this.name,
    required this.canSendMessage,
    this.type,
    required this.chatUsers,
    this.group,
    required this.channelName,
  });

  factory ChatsGetId.fromJson(Map<String, dynamic> json) {
    // Теперь json уже есть 'result' внутри, но в методе getChatById мы передаём json['result']
    final data = json; // Предполагаем, что json - это уже result
    if (data == null) {
      throw Exception("Ответ не содержит данных");
    }

    // Парсинг chatUsers: если есть user, создаём ChatUser с type 'user', иначе пустой список
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

    // Имя: для lead из integration.name или channel.name, иначе пусто
    String name = '';
    String channelName = '';
    if (data['type'] == 'lead') {
      channelName = data['channel']?['name'] ?? 'telegram_account'; // По умолчанию из примера
      name = data['integration']?['name'] ?? channelName; // Fallback, но integration может быть неполным
    }

    return ChatsGetId(
      id: data['id'] ?? 0,
      name: name,
      canSendMessage: data["can_send_message"] ?? false,
      type: data['type'],
      chatUsers: chatUsersList,
      group: data['group'] != null ? Group.fromJson(data['group']) : null,
      channelName: channelName,
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

