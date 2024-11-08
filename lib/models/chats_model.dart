import 'package:crm_task_manager/screens/chats/chats_items.dart';

class Chats {
  final int id;
  final String name;
  final String taskFrom;
  final String taskTo;
  final String description;
  final String channel;
  final String lastMessage;
  final String messageType;
  final String createDate;
  final int unredMessage;

  Chats({
    required this.id,
    required this.name,
    required this.taskFrom,
    required this.taskTo,
    required this.description,
    required this.channel,
    required this.lastMessage,
    required this.messageType,
    required this.createDate,
    required this.unredMessage,
  });

  factory Chats.fromJson(Map<String, dynamic> json) {
    print('----- for test');
    print(json);
    return Chats(
      id: json['id'] ?? 0, // Предположим, что ID должен быть числом, иначе 0
      name: json['task'] != null
          ? json['task']['name'] ?? ''
          : json['lead'] != null
              ? json['lead']['name'] ?? 'Без имени'
              : '',
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
    );
  }

  static String _getLastMessageText(Map<String, dynamic> lastMessage) {
    switch (lastMessage['type']) {
      case 'text':
        return lastMessage['text'] ?? 'Текстовое сообщение';
      case 'voice':
        return 'Вам пришло голосовое сообщение';
      case 'file':
        return lastMessage['text'] ?? 'Файл: неизвестное имя';
      case 'image':
        return lastMessage['text'] ?? 'Изображение';
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

  ChatItem toChatItem(String avatar) {
    return ChatItem(
      name,
      lastMessage,
      createDate,
      avatar,
      _mapChannelToIcon(channel),
      unredMessage,
    );
  }

  @override
  String toString() {
    return 'Chats{id: $id, name: $name, taskFrom: $taskFrom, taskTo: $taskTo, description: $description, channel: $channel, lastMessage: $lastMessage, messageType: $messageType, createDate: $createDate, unredMessage: $unredMessage}';
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

class Message {
  final int id;
  final String text;
  final String type;
  final String? filePath;
  final bool isMyMessage;
  final String createMessateTime;
  bool isPlaying;
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
