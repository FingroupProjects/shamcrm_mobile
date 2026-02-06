import 'package:crm_task_manager/models/integration_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/message_reaction_model.dart'; // Из ветки reaction
import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';
import 'package:crm_task_manager/utils/global_value.dart';
import 'package:flutter/material.dart';

class Integration {
  final int? id;
  final String? name;
  final String? username;

  Integration({this.id, this.name, this.username});

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
  final String channel;
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
  final Channel? channelObj;
  final Integration? integration;

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

  factory Chats.fromJson(Map<String, dynamic> json, {String? supportChatName, String? supportChatImage}) {
    List<ChatUser> users = [];
    if (json['chatUsers'] != null) {
      for (var userJson in json['chatUsers']) {
        users.add(ChatUser.fromJson(userJson));
      }
    }

    Group? group;
    if (json['group'] != null) group = Group.fromJson(json['group']);

    Task? task;
    if (json['task'] != null) {
      task = Task.fromJson(json['task'], json['task']['status_id'] ?? 0);
    }

    ChatUser? user;
    if (json['user'] != null) user = ChatUser.fromJson({'participant': json['user']});

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
      createDate: json['lastMessage'] != null ? json['lastMessage']['created_at'] ?? '' : '',
      unreadCount: json['unread_count'] ?? 0,
      taskFrom: json['task'] != null ? json['task']['from'] ?? '' : '',
      taskTo: json['task'] != null ? json['task']['to'] ?? '' : '',
      description: json['task'] != null ? json['task']['description'] ?? '' : '',
      channel: json['channel'] != null ? json['channel']['name'] ?? '' : '',
      lastMessage: json['lastMessage'] != null ? _getLastMessageText(json['lastMessage']) : '',
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
    if (type == 'support' && customName != null) return customName;
    if (group != null && group!.name.isNotEmpty) return group!.name;
    if (task != null && task!.name!.isNotEmpty) return task!.name;
    return name;
  }

  static String _getLastMessageText(Map<String, dynamic> lastMessage) {
    final isMyMessage = lastMessage['is_my_message'] ?? false;
    switch (lastMessage['type']) {
      case 'text': return lastMessage['text'] ?? 'Текстовое сообщение';
      case 'voice': return isMyMessage ? 'Отправлено голосовое сообщение' : 'Вам пришло голосовое сообщение';
      case 'file': return 'Файл: неизвестное имя';
      case 'image': return 'Изображение';
      case 'video': return 'Вам пришло видео сообщение';
      case 'location': return 'Вам пришло местоположение: ${lastMessage['location'] ?? 'неизвестно'}';
      case 'sticker': return 'Вам пришел стикер';
      default: return 'Новое сообщение';
    }
  }

  Chats copyWith({
    int? id, String? uniqueId, String? name, String? image, String? taskFrom,
    String? taskTo, String? description, String? channel, String? lastMessage,
    String? messageType, String? createDate, int? unreadCount, bool? canSendMessage,
    String? type, List<ChatUser>? chatUsers, Group? group, Task? task, ChatUser? user,
    String? customName, String? customImage, Channel? channelObj, Integration? integration,
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
        avatar = (chatUsers[1].id == currentUserId) ? chatUsers[1].image : chatUsers[0].image;
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
    final normalized = channel.replaceAll('channel-', '');
    const channelIconMap = {
      'mini_app': 'assets/icons/leads/telegram.png',
      'telegram_bot': 'assets/icons/leads/telegram.png',
      'telegram_account': 'assets/icons/leads/telegram.png',
      'whatsapp': 'assets/icons/leads/whatsapp.png',
      'instagram': 'assets/icons/leads/instagram.png',
      'instagram_comment': 'assets/icons/leads/instagram.png',
      'facebook': 'assets/icons/leads/messenger.png',
      'messenger': 'assets/icons/leads/messenger.png',
      'phone': 'assets/icons/leads/telefon.png',
      'email': 'assets/icons/leads/email.png',
      'site': '', // Используется Flutter иконка Icons.language
    };
    return channelIconMap[normalized] ?? 'assets/icons/leads/default.png';
  }
}

class ChatUser {
  final int id;
  final String name;
  final String login;
  final String email;
  final String phone;
  final String image;
  final String? lastSeen;

  ChatUser({required this.id, required this.name, required this.login, required this.email, required this.phone, required this.image, this.lastSeen});

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['participant'] != null ? json['participant']['id'] ?? 0 : 0,
      name: json['participant'] != null ? json['participant']['name'] ?? '' : '',
      login: json['participant'] != null ? json['participant']['login'] ?? '' : '',
      email: json['participant'] != null ? json['participant']['email'] ?? '' : '',
      phone: json['participant'] != null ? json['participant']['phone'] ?? '' : '',
      image: json['participant'] != null ? json['participant']['image'] ?? '' : '',
      lastSeen: json['participant'] != null ? json['participant']['last_seen'] : null,
    );
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

  Group({required this.id, required this.name, this.imgUrl, required this.authorId, required this.createdAt, required this.updatedAt, required this.organizationId});

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
  final Post? post;
  bool isPinned;
  bool isChanged;
  bool isRead;
  final bool isNote; // Новое поле
  final ReadStatus? readStatus;
  final String? referralBody;
  final List<MessageReaction> reactions; // Сохранено из ветки reaction

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
    this.post,
    this.isPinned = false,
    this.isChanged = false,
    this.isNote = false,
    this.isRead = false,
    this.readStatus,
    this.referralBody,
    this.reactions = const [], // Сохранено из ветки reaction
  });

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
    Post? post,
    bool? isPinned,
    bool? isChanged,
    bool? isRead,
    bool? isNote, // Новое поле

    ReadStatus? readStatus,
    List<MessageReaction>? reactions, // Сохранено из ветки reaction
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
      post: post ?? this.post,
      isPinned: isPinned ?? this.isPinned,
      isChanged: isChanged ?? this.isChanged,
      isRead: isRead ?? this.isRead,
      readStatus: readStatus ?? this.readStatus,
      isNote: isNote ?? this.isNote,
      reactions: reactions ?? this.reactions,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json, {String? chatType}) {
    String text = (json['type'] == 'file') ? (json['text'] ?? 'unknown_file') : (json['text'] ?? '');
    
    ReadStatus? readStatus;
    try {
      if (json['read_status'] != null) readStatus = ReadStatus.fromJson(json['read_status']);
    } catch (e) {
      readStatus = null;
    }

    // ✅ ЛОГИКА ИЗ ВЕТКИ 1 (Приоритет по ID пользователя)
    bool isMyMessage = false;
    final senderId = json['sender']?['id']?.toString();
    final myUserId = userID.value;

    if (senderId != null && senderId.isNotEmpty && myUserId.isNotEmpty) {
      isMyMessage = (senderId == myUserId);
    } else {
      if (json['sender'] != null && json['sender']['type'] != null) {
        final senderType = json['sender']['type'].toString();
        final effectiveChatType = chatType ?? json['chat']?['type']?.toString();
        if (senderType == 'lead') {
          isMyMessage = false;
        } else if (senderType == 'user' && effectiveChatType == 'lead') {
          isMyMessage = true;
        } else {
          isMyMessage = json['is_my_message'] ?? false;
        }
      } else {
        isMyMessage = json['is_my_message'] ?? false;
      }
    }

    // ✅ ПЕРЕСЫЛКА ИЗ ВЕТКИ 1 (с очисткой HTML)
    ForwardedMessage? forwardedMessage;
    if (json['forwarded_message'] != null) {
      try {
        forwardedMessage = ForwardedMessage.fromJson(json['forwarded_message']);
      } catch (_) {
        try {
          final fJson = json['forwarded_message'];
          forwardedMessage = ForwardedMessage(
            id: fJson['id'] ?? 0,
            text: _stripHtmlTags(fJson['text'] ?? ''),
            type: fJson['type'] ?? 'text',
            senderName: fJson['sender']?['name'] ?? 'Без имени',
          );
        } catch (_) {}
      }
    }

    Post? post;
    if (json['post'] != null) {
      try {
        post = Post.fromJson(json['post']);
      } catch (_) {}
    }

    // ✅ РЕАКЦИИ ИЗ ВЕТКИ REACTION
    List<MessageReaction> reactionsList = [];
    if (json['reactions'] != null && json['reactions'] is List) {
      for (var reactionJson in json['reactions']) {
        reactionsList.add(MessageReaction.fromJson(reactionJson));
      }
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
      post: post,
      isRead: json['is_read'] ?? false,
      readStatus: readStatus,
      isNote: json['is_note'] ?? false,
      reactions: reactionsList,
      duration: Duration(
        seconds: json['voice_duration'] != null
            ? double.tryParse(json['voice_duration'].toString())?.round() ?? 0
            : 20,
      ),
    );
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

  ForwardedMessage({required this.id, required this.text, required this.type, this.senderName});

  factory ForwardedMessage.fromJson(Map<String, dynamic> json) {
    return ForwardedMessage(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      type: json['type'] ?? 'text',
      senderName: json['sender']?['name'] ?? 'Без имени',
    );
  }
  @override
  String toString() {
    return 'ForwardedMessage{id: $id, text: $text, type: $type, senderName: $senderName}';
  }
}

class Post {
  final int id;
  final String caption;
  final String? mediaUrl;

  Post({
    required this.id,
    required this.caption,
    this.mediaUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? 0,
      caption: json['caption']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString(),
    );
  }

  @override
  String toString() {
    return 'Post{id: $id, caption: $caption, mediaUrl: $mediaUrl}';
  }
}

class ReadStatus {
  final List<User> read;
  final List<User> unread;
  ReadStatus({required this.read, required this.unread});

  factory ReadStatus.fromJson(Map<String, dynamic> json) {
    return ReadStatus(
      read: (json['read'] as List<dynamic>?)?.map((e) {
            DateTime? readAt = e['read_at'] != null ? DateTime.tryParse(e['read_at']) : null;
            return User.fromJson(e['user'], readAt);
          }).toList() ?? [],
      unread: (json['unread'] as List<dynamic>?)?.map((e) => User.fromJson(e['user'], null)).toList() ?? [],
    );
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
  final String fullName;
  final DateTime? readAt;

  User({required this.id, required this.name, required this.lastname, this.login, this.email, this.phone, this.image, this.lastSeen, required this.fullName, this.readAt});

  factory User.fromJson(Map json, [DateTime? readAt]) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      lastname: json['lastname'] ?? '',
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
      image: json['image'],
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : DateTime.now(),
      fullName: json['full_name'] ?? 'Без имени',
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : readAt,
    );
  }
}

// ✅ ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ИЗ ВЕТКИ 1
String _stripHtmlTags(String html) {
  if (!html.contains('<') || !html.contains('>')) return html;
  try {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  } catch (e) {
    return html;
  }
}
