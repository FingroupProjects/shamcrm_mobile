
class ChatsGetId {
  final int id;
  final String name;
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

  ChatsGetId({
    required this.id,
    required this.name,
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
  });

  factory ChatsGetId.fromJson(Map<String, dynamic> json) {
  final data = json['result']; // Здесь достаем вложенные данные
  if (data == null) {
    throw Exception("Ответ не содержит поля 'result'");
  }
  return ChatsGetId(
    id: data['id'] ?? 0,
    name: data['lead'] != null
        ? data['lead']['name'] ?? 'Без имени'
        : '',
    createDate: data['lead'] != null
        ? data['lead']['created_at'] ?? ''
        : '',
    unredMessage: data['lead'] != null
        ? data['lead']['unread_messages_count'] ?? 0
        : 0,
    taskFrom: '',
    taskTo: '',
    description: '',
    channel: data['lead']?['channels']?.first['name'] ?? '',
    lastMessage: '',
    messageType: '',
    canSendMessage: data["can_send_message"] ?? false,
    type: data['type'],
  );
}

}