import 'package:crm_task_manager/models/integration_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';
import 'package:flutter/material.dart';

class Integration {
  final int? id;
  final String? name;
  final String? username;

  Integration({
    this.id,
    this.name,
    this.username,
  });

  factory Integration.fromJson(Map<String, dynamic> json) {
    return Integration(
      id: json['id'] as int?,
      name: json['name'] as String?,
      username: json['username'] as String?,
    );
  }
}

class Chats {
  final int id;
  final String? uniqueId;
  final String name;
  final String image;
  final String? taskFrom;
  final String? taskTo;
  final String? description;
  final String channel; // Это поле будет содержать channel.name
  final String lastMessage;
  final String? messageType;
  final String createDate;
  int unreadCount;
  final bool canSendMessage;
  final String? type;
  final List<ChatUser> chatUsers;
  final Group? group;
  final Task? task;
  final ChatUser? user;
  final String? customName;
  final String? customImage;
  final Channel? channelObj; // Новое поле для полного объекта Channel
  final Integration? integration; // Новое поле для объекта Integration

  Chats({
    required this.id,
    this.uniqueId,
    required this.name,
    required this.image,
    this.taskFrom,
    this.taskTo,
    this.description,
    required this.channel,
    required this.lastMessage,
    this.messageType,
    required this.createDate,
    required this.unreadCount,
    required this.canSendMessage,
    this.type,
    required this.chatUsers,
    this.group,
    this.task,
    this.user,
    this.customName,
    this.customImage,
    this.channelObj,
    this.integration,
  });

  factory Chats.fromJson(
    Map<String, dynamic> json, {
    String? supportChatName,
    String? supportChatImage,
  }) {
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

    String? customName;
    String? customImage;
    if (json['type'] == 'support') {
      customName = json['type'];
      customImage = supportChatImage ?? 'assets/icons/Profile/image.png';
    }

    return Chats(
      id: json['id'] ?? 0,
      uniqueId: json['unique_id'] as String?,
      name: json['user'] != null
          ? json['user']['name'] ?? 'Без имени'
          : json['task'] != null
              ? json['task']['name'] ?? ''
              : json['lead'] != null
                  ? json['lead']['name'] ?? 'Без имени'
                  : '',
      image: json['image'] ?? '',
      user: user,
      customName: customName,
      customImage: customImage,
      createDate: json['lastMessage'] != null
          ? json['lastMessage']['created_at'] ?? ''
          : '',
      unreadCount: json['unread_count'] ?? 0,
      taskFrom: json['task'] != null ? json['task']['from'] ?? '' : '',
      taskTo: json['task'] != null ? json['task']['to'] ?? '' : '',
      description: json['task'] != null ? json['task']['description'] ?? '' : '',
      channel: json['channel'] != null ? json['channel']['name'] ?? '' : '',
      lastMessage: json['lastMessage'] != null
          ? _getLastMessageText(json['lastMessage'])
          : '',
      messageType: json['lastMessage'] != null ? json['lastMessage']['type'] ?? '' : '',
      canSendMessage: json['can_send_message'] ?? false,
      type: json['type'],
      chatUsers: users,
      group: group,
      task: task,
      channelObj: json['channel'] != null ? Channel.fromJson(json['channel']) : null,
      integration: json['integration'] != null ? Integration.fromJson(json['integration']) : null,
    );
  }

  String? get displayName {
    if (type == 'support' && customName != null) {
      return customName;
    } else if (group != null && group!.name.isNotEmpty) {
      return group!.name;
    } else if (task != null && task!.name!.isNotEmpty) {
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

  Chats copyWith({
    int? id,
    String? uniqueId,
    String? name,
    String? image,
    String? taskFrom,
    String? taskTo,
    String? description,
    String? channel,
    String? lastMessage,
    String? messageType,
    String? createDate,
    int? unreadCount,
    bool? canSendMessage,
    String? type,
    List<ChatUser>? chatUsers,
    Group? group,
    Task? task,
    ChatUser? user,
    String? customName,
    String? customImage,
    Channel? channelObj,
    Integration? integration,
  }) {
    return Chats(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      name: name ?? this.name,
      image: image ?? this.image,
      taskFrom: taskFrom ?? this.taskFrom,
      taskTo: taskTo ?? this.taskTo,
      description: description ?? this.description,
      channel: channel ?? this.channel,
      lastMessage: lastMessage ?? this.lastMessage,
      messageType: messageType ?? this.messageType,
      createDate: createDate ?? this.createDate,
      unreadCount: unreadCount ?? this.unreadCount,
      canSendMessage: canSendMessage ?? this.canSendMessage,
      type: type ?? this.type,
      chatUsers: chatUsers ?? this.chatUsers,
      group: group ?? this.group,
      task: task ?? this.task,
      user: user ?? this.user,
      customName: customName ?? this.customName,
      customImage: customImage ?? this.customImage,
      channelObj: channelObj ?? this.channelObj,
      integration: integration ?? this.integration,
    );
  }

  ChatItem toChatItem() {
    String avatar;
    if (type == 'support' && customImage != null) {
      avatar = customImage!;
    } else if (group != null) {
      avatar = "assets/images/GroupChat.png";
    } else if (chatUsers.isNotEmpty) {
      int currentUserId = user?.id ?? 0;
      if (chatUsers.length > 1) {
        if (chatUsers[1].id == currentUserId) {
          avatar = chatUsers[1].image;
        } else {
          avatar = chatUsers[0].image;
        }
      } else {
        avatar = chatUsers[0].image;
      }
    } else {
      avatar = "assets/images/AvatarChat.png";
    }

    return ChatItem(
      displayName!,
      lastMessage,
      createDate,
      avatar,
      _mapChannelToIcon(channel),
      unreadCount,
    );
  }

  String _mapChannelToIcon(String channel) {
    const channelIconMap = {
      'mini_app': 'assets/icons/leads/telegram.png',
      'telegram_bot': 'assets/icons/leads/telegram.png',
      'telegram_account': 'assets/icons/leads/telegram.png',
      'whatsapp': 'assets/icons/leads/whatsapp.png',
      'instagram': 'assets/icons/leads/instagram.png',
      'facebook': 'assets/icons/leads/messenger.png',
      'messenger': 'assets/icons/leads/messenger.png',
      'phone': 'assets/icons/leads/telefon.png',
      'email': 'assets/icons/leads/email.png',
      'site': '', // Используется Flutter иконка Icons.language
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
  final ForwardedMessage? forwardedMessage;
  bool isPinned;
  bool isChanged;
  bool isRead;
  final bool isNote; // Новое поле
  final ReadStatus? readStatus;
  final String? referralBody;

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
    this.forwardedMessage,
    this.isPinned = false,
    this.isChanged = false,
    this.isNote = false, // Инициализация по умолчанию
    this.isRead = false,
    this.readStatus,
    this.referralBody,
  });

  // Метод copyWith
  Message copyWith({
    int? id,
    String? text,
    String? type,
    String? filePath,
    bool? isMyMessage,
    String? createMessateTime,
    bool? isPlaying,
    String? senderName,
    bool? isPause,
    Duration? duration,
    Duration? position,
    ForwardedMessage? forwardedMessage,
    bool? isPinned,
    bool? isChanged,
    bool? isRead,
    bool? isNote, // Новое поле
    
    ReadStatus? readStatus,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      isMyMessage: isMyMessage ?? this.isMyMessage,
      createMessateTime: createMessateTime ?? this.createMessateTime,
      isPlaying: isPlaying ?? this.isPlaying,
      senderName: senderName ?? this.senderName,
      isPause: isPause ?? this.isPause,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      forwardedMessage: forwardedMessage ?? this.forwardedMessage,
      isPinned: isPinned ?? this.isPinned,
      isChanged: isChanged ?? this.isChanged,
      isRead: isRead ?? this.isRead,
      readStatus: readStatus ?? this.readStatus,
      isNote: isNote ?? this.isNote, // Новое поле
    );
  }

  factory Message.fromJson(Map<String, dynamic> json, {String? chatType}) {
    String text;
    if (json['type'] == 'file') {
      text = json['text'] ?? 'unknown_file';
    } else {
      text = json['text'] ?? '';
    }
    ForwardedMessage? forwardedMessage;
    if (json['forwarded_message'] != null) {
      forwardedMessage = ForwardedMessage.fromJson(json['forwarded_message']);
    }
    ReadStatus? readStatus;
    try {
      if (json['read_status'] != null) {
        readStatus = ReadStatus.fromJson(json['read_status']);
      }
    } catch (e) {
      debugPrint('Error parsing read_status: $e');
      readStatus = null;
    }
    
    // ✅ ПРАВИЛЬНАЯ ЛОГИКА для определения isMyMessage:
    // Специальная логика ТОЛЬКО для ЛИДОВ (когда chat.type == 'lead')
    // В корпоративных чатах и задачах используем стандартную логику с сервера
    bool isMyMessage;
    
    // 🔍 ДИАГНОСТИКА: Смотрим что приходит
    debugPrint('🔍 Message.fromJson ДИАГНОСТИКА:');
    debugPrint('   json["chat"] = ${json['chat']}');
    debugPrint('   json["chat"]["type"] = ${json['chat']?['type']}');
    debugPrint('   json["sender"] = ${json['sender']}');
    debugPrint('   json["sender"]["type"] = ${json['sender']?['type']}');
    debugPrint('   json["sender"]["name"] = ${json['sender']?['name']}');
    debugPrint('   json["is_my_message"] = ${json['is_my_message']}');
    
    // ✅ УПРОЩЁННАЯ ЛОГИКА:
    // Если приходит sender.type, используем его для определения:
    // - sender.type == 'lead' → это ЛИДНЫЙ чат, сообщение от лида → isMyMessage = FALSE (слева)
    // - sender.type == 'user' + chatType == 'lead' → ЛИДНЫЙ чат, сообщение от менеджера → isMyMessage = TRUE (справа)
    // - Иначе → используем is_my_message с сервера (для корпоративных чатов и задач)
    
    if (json['sender'] != null && json['sender']['type'] != null) {
      final senderType = json['sender']['type'].toString();
      final senderName = json['sender']['name']?.toString() ?? 'Unknown';
      // Используем переданный chatType или берём из JSON (приоритет у переданного)
      final effectiveChatType = chatType ?? json['chat']?['type']?.toString();
      
      debugPrint('   → senderType = $senderType');
      debugPrint('   → chatType (переданный) = $chatType');
      debugPrint('   → json["chat"]["type"] = ${json['chat']?['type']}');
      debugPrint('   → effectiveChatType (используемый) = $effectiveChatType');
      
      if (senderType == 'lead') {
        // ✅ Если отправитель - ЛИД, это точно лидный чат
        isMyMessage = false;
        debugPrint('🎯 [LEAD CHAT] sender.type=lead (клиент: $senderName) → isMyMessage=FALSE (слева)');
      } else if (senderType == 'user' && effectiveChatType == 'lead') {
        // ✅ Если отправитель - USER и чат лидный
        isMyMessage = true;
        debugPrint('🎯 [LEAD CHAT] sender.type=user + chatType=lead (менеджер: $senderName) → isMyMessage=TRUE (справа)');
      } else {
        // ✅ Корпоративный чат или задача - используем стандартную логику
        isMyMessage = json['is_my_message'] ?? false;
        debugPrint('🎯 [CORPORATE/TASK] sender.type=$senderType, chatType=$effectiveChatType → is_my_message=$isMyMessage (с сервера)');
      }
    } else {
      // Нет sender.type - используем стандартную логику
      isMyMessage = json['is_my_message'] ?? false;
      debugPrint('🎯 [FALLBACK] НЕТ sender.type → is_my_message=$isMyMessage (с сервера)');
    }
    
    return Message(
        id: json['id'],
        text: text,
        type: json['type'],
        senderName: json['sender'] == null
            ? 'Без имени'
            : json['sender']['name'] ?? 'Без имени',
        referralBody: json['chat']?['referral_body'],
        createMessateTime: json['created_at'] ?? '',
        filePath: json['file_path'],
        isPinned: json['is_pinned'] ?? false,
        isChanged: json['is_changed'] ?? false,
        isMyMessage: isMyMessage,
        forwardedMessage: forwardedMessage,
        isRead: json['is_read'] ?? false,
        readStatus: readStatus,
        isNote: json['is_note'] ?? false, // Парсинг is_note
        duration: Duration(
          seconds: json['voice_duration'] != null
              ? double.tryParse(json['voice_duration'].toString())?.round() ?? 0
              : 20,
        ));
  }

  @override
  String toString() {
    return 'Message{id: $id, text: $text, type: $type, filePath: $filePath, isMyMessage: $isMyMessage, isPlaying: $isPlaying, isPause: $isPause, duration: $duration, position: $position, forwardedMessage: $forwardedMessage, isPinned: $isPinned, isChanged: $isChanged, isRead: $isRead, readStatus: $readStatus}';
  }
}

class ForwardedMessage {
  final int id;
  final String text;
  final String type;
  final String? senderName;

  ForwardedMessage({
    required this.id,
    required this.text,
    required this.type,
    this.senderName,
  });

  factory ForwardedMessage.fromJson(Map<String, dynamic> json) {
    return ForwardedMessage(
      id: json['id'],
      text: json['text'] ?? '',
      type: json['type'],
      senderName: json['sender']?['name'] ?? 'Без имени',
    );
  }

  @override
  String toString() {
    return 'ForwardedMessage{id: $id, text: $text, type: $type, senderName: $senderName}';
  }
}

class ReadStatus {
  final List<User> read;
  final List<User> unread;

  ReadStatus({
    required this.read,
    required this.unread,
  });

  factory ReadStatus.fromJson(Map<String, dynamic> json) {
    return ReadStatus(
      read: (json['read'] as List<dynamic>?)?.map((e) {
            DateTime? readAt =
                e['read_at'] != null ? DateTime.tryParse(e['read_at']) : null;
            return User.fromJson(e['user'], readAt);
          }).toList() ??
          [],
      unread: (json['unread'] as List<dynamic>?)
              ?.map((e) => User.fromJson(e['user'], null))
              .toList() ??
          [],
    );
  }
}

class ReadUser {
  final int userId;
  final String readAt;
  final User user;

  ReadUser({
    required this.userId,
    required this.readAt,
    required this.user,
  });

  @override
  String toString() {
    return 'ReadUser{userId: $userId, readAt: $readAt, user: $user}';
  }
}

class User {
  final int id;
  final String name;
  final String lastname;
  final String? login;
  final String? email;
  final String? phone;
  final String? image;
  final DateTime? lastSeen;
  final DateTime? deletedAt;
  final String? telegramUserId;
  final String? jobTitle;
  final bool? online;
  final String fullName;
  final DateTime? readAt;

  User({
    required this.id,
    required this.name,
    required this.lastname,
    required this.login,
    required this.email,
    required this.phone,
    required this.image,
    required this.lastSeen,
    this.deletedAt,
    this.telegramUserId,
    this.jobTitle,
    this.online,
    required this.fullName,
    this.readAt,
  });

  factory User.fromJson(Map json, [DateTime? readAt]) {
    DateTime? parsedReadAt;

    if (json['read_at'] != null) {
      parsedReadAt = DateTime.tryParse(json['read_at']) ?? readAt;
    } else if (readAt != null) {
      parsedReadAt = readAt;
    }

    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      lastname: json['lastname'] ?? '',
      login: json['login'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      image: json['image'] ?? '',
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : DateTime.now(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
      telegramUserId: json['telegram_user_id'],
      jobTitle: json['job_title'],
      online: json['online'] ?? false,
      fullName: json['full_name'] ?? 'Без имени',
      readAt: parsedReadAt,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, lastname: $lastname, login: $login, email: $email, phone: $phone, image: $image, lastSeen: $lastSeen, deletedAt: $deletedAt, telegramUserId: $telegramUserId, jobTitle: $jobTitle, online: $online, fullName: $fullName,readAt: $readAt}';
  }
}