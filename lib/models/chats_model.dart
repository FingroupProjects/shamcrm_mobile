class Chats {
  final int id;
  final String name;
  final String taskFrom;
  final String taskTo;
  final String description;
  final String channel;
  final String lastMessage;
  final String messageType;

  Chats({
    required this.id,
    required this.name,
    required this.taskFrom,
    required this.taskTo,
    required this.description,
    required this.channel,
    required this.lastMessage,
    required this.messageType,
  });

  factory Chats.fromJson(Map<String, dynamic> json) {
    return Chats(
      id: json['id'] ?? 0, // Предположим, что ID должен быть числом, иначе 0
      name: json['task'] != null
          ? json['task']['name'] ?? ''
          : json['lead'] != null
              ? json['lead']['name'] ?? 'Без имени'
              : '',
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
}

class Message {
  final int id;
  final String text;
  final String type;
  final String? filePath;
  final bool isMyMessage;


  Message({
    required this.id,
    required this.text,
    required this.type,
    this.filePath,
    required this.isMyMessage,
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
      filePath: json['file_path'],
      isMyMessage: json['is_my_message'] ?? false,
    );
  }
}









  // var audioUrl;
