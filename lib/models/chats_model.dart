import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';

class Chats {
  final int id;
  final String name;
  final String image;
  final String? taskFrom;
  final String? taskTo;
  final String? description;
  final String channel;
  final String lastMessage;
  final String? messageType;
  final String createDate;
  final int unredMessage;
  final bool canSendMessage;
  final String? type;
  final List<ChatUser> chatUsers;
  final Group? group;
  final Task? task;
  final ChatUser? user; // добавим поле user

  Chats({
    required this.id,
    required this.name,
    required this.image,
    this.taskFrom,
    this.taskTo,
    this.description,
    required this.channel,
    required this.lastMessage,
    this.messageType,
    required this.createDate,
    required this.unredMessage,
    required this.canSendMessage,
    this.type,
    required this.chatUsers,
    this.group,
    this.task,
    this.user, // добавим в конструктор
  });

  factory Chats.fromJson(Map<String, dynamic> json) {
    List<ChatUser> users = [];
    if (json['chatUsers'] != null) {
      for (var userJson in json['chatUsers']) {
        users.add(ChatUser.fromJson(userJson));
      }
    }

    Group? group;
    if (json['group'] != null) {
      group = Group.fromJson(json['group']);
    }

    Task? task;
    if (json['task'] != null) {
      task = Task.fromJson(json['task'], json['task']['status_id'] ?? 0);
    }
    ChatUser? user;
    if (json['user'] != null) {
      user = ChatUser.fromJson({'participant': json['user']});
    }
    return Chats(
      id: json['id'] ?? 0,
      name: json['user'] != null
          ? json['user']['name']
          : json['task'] != null
              ? json['task']['name'] ?? ''
              : json['lead'] != null
                  ? json['lead']['name'] ?? 'Без имени'
                  : '',
      image: json['image'] ?? '',
      user: user,
      createDate: json['task'] != null
          ? json['task']['created_at'] ?? ''
          : json['lead'] != null
              ? json['lead']['created_at'] ?? ''
              : '',
      unredMessage: json['task'] != null
          ? json['task']['unread_messages_count'] ?? 0
          : json['lead'] != null
              ? json['lead']['unread_messages_count'] ?? 0
              : 0,
      taskFrom: json['task'] != null ? json['task']['from'] ?? '' : '',
      taskTo: json['task'] != null ? json['task']['to'] ?? '' : '',
      description:
          json['task'] != null ? json['task']['description'] ?? '' : '',
      channel: json['channel'] != null ? json['channel']['name'] ?? '' : '',
      lastMessage: json['lastMessage'] != null
          ? _getLastMessageText(json['lastMessage'])
          : '',
      messageType:
          json['lastMessage'] != null ? json['lastMessage']['type'] ?? '' : '',
      canSendMessage: json["can_send_message"] ?? false,
      type: json['type'],
      chatUsers: users,
      group: group,
      task: task,
    );
  }

  String get displayName {
    if (group != null && group!.name.isNotEmpty) {
      return group!.name;
    } else if (task != null && task!.name.isNotEmpty) {
      return task!.name;
    } else {
      return name;
    }
  }

  static String _getLastMessageText(Map<String, dynamic> lastMessage) {
    final isMyMessage = lastMessage['is_my_message'] ?? false;
    switch (lastMessage['type']) {
      case 'text':
        return lastMessage['text'] ?? 'Текстовое сообщение';
      case 'voice':
        return isMyMessage
            ? 'Отправлено голосовое сообщение'
            : 'Вам пришло голосовое сообщение';
      case 'file':
        return 'Файл: неизвестное имя';
      case 'image':
        return 'Изображение';
      case 'video':
        return 'Вам пришло видео сообщение';
      case 'location':
        return 'Вам пришло местоположение: ${lastMessage['location'] ?? 'неизвестно'}';
      case 'sticker':
        return 'Вам пришел стикер';
      default:
        return 'Новое сообщение';
    }
  }

   ChatItem toChatItem() {
    String avatar;
    if (group != null) {
      avatar = "assets/images/GroupChat.png";
    } else if (chatUsers.isNotEmpty) {
      // Получаем ID текущего пользователя из поля user
      int currentUserId = user?.id ?? 0;
      print('Current user ID: $currentUserId'); // для отладки
      
      if (chatUsers.length > 1) {
        if (chatUsers[1].id == currentUserId) {
          // Если первый пользователь - это текущий пользователь,
          // показываем аватар второго
          avatar = chatUsers[1].image;
        } else {
          // Иначе показываем аватар первого
          avatar = chatUsers[0].image;
        }
      } else {
        avatar = chatUsers[0].image;
      }
    } else {
      avatar = "assets/images/AvatarChat.png";
    }
    
    return ChatItem(
      displayName,
      lastMessage,
      createDate,
      avatar,
      _mapChannelToIcon(channel),
      unredMessage,
    );
  }

  String _mapChannelToIcon(String channel) {
    const channelIconMap = {
      'telegram_bot': 'assets/icons/leads/telegram.png',
      'telegram_account': 'assets/icons/leads/telegram.png',
      'whatsapp': 'assets/icons/leads/whatsapp.png',
      'instagram': 'assets/icons/leads/instagram.png',
      'facebook': 'assets/icons/leads/facebook.png',
    };
    return channelIconMap[channel] ?? 'assets/icons/leads/default.png';
  }
}

// New ChatUser class
class ChatUser {
  final int id;
  final String name;
  final String login;
  final String email;
  final String phone;
  final String image;
  final String? lastSeen;

  ChatUser({
    required this.id,
    required this.name,
    required this.login,
    required this.email,
    required this.phone,
    required this.image,
    this.lastSeen,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['participant'] != null ? json['participant']['id'] ?? 0 : 0,
      name:
          json['participant'] != null ? json['participant']['name'] ?? '' : '',
      login:
          json['participant'] != null ? json['participant']['login'] ?? '' : '',
      email:
          json['participant'] != null ? json['participant']['email'] ?? '' : '',
      phone:
          json['participant'] != null ? json['participant']['phone'] ?? '' : '',
      image:
          json['participant'] != null ? json['participant']['image'] ?? '' : '',
      lastSeen:
          json['participant'] != null ? json['participant']['last_seen'] : null,
    );
  }

  @override
  String toString() {
    return 'ChatUser{id: $id, name: $name, login: $login, email!mail, phone: $phone, image: $image, lastSeen: $lastSeen}';
  }
}

class Group {
  final int id;
  final String name;
  final String? imgUrl;
  final int authorId;
  final String createdAt;
  final String updatedAt;
  final int organizationId;

  Group({
    required this.id,
    required this.name,
    this.imgUrl,
    required this.authorId,
    required this.createdAt,
    required this.updatedAt,
    required this.organizationId,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imgUrl: json['img_url'],
      authorId: json['author_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      organizationId: json['organization_id'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'Group{id: $id, name: $name, imgUrl: $imgUrl, authorId: $authorId, createdAt: $createdAt, updatedAt: $updatedAt, organizationId: $organizationId}';
  }
}

class Message {
  final int id;
  final String text;
  final String type;
  final String? filePath;
  final bool isMyMessage;
  final String createMessateTime;
  bool isPlaying;
  String senderName;
  bool isPause;
  Duration duration;
  Duration position;

  Message({
    required this.id,
    required this.text,
    required this.type,
    this.filePath,
    required this.isMyMessage,
    required this.createMessateTime,
    required this.senderName,
    this.isPlaying = false,
    this.isPause = false,
    this.duration = const Duration(),
    this.position = const Duration(),
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    String text;

    // Если тип сообщения 'file', используем text напрямую
    if (json['type'] == 'file') {
      text = json['text'] ?? 'unknown_file'; // Используем text для имени файла
    } else {
      text = json['text'] ?? '';
    }

    return Message(
      id: json['id'],
      text: text, // Убедитесь, что именно text используется
      type: json['type'],
      senderName: json['sender'] == null
          ? 'Без имени'
          : json['sender']['name'] ?? 'Без имени',
      createMessateTime: json['created_at'] ?? '',
      filePath: json['file_path'],
      isMyMessage: json['is_my_message'] ?? false,
    );
  }

  @override
  String toString() {
    return 'Message{id: $id, text: $text, type: $type, filePath: $filePath, isMyMessage: $isMyMessage, isPlaying: $isPlaying, isPause: $isPause, duration: $duration, position: $position}';
  }
}

// var audioUrl;
