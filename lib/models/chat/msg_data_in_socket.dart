import 'dart:convert';

MessageSocketData messageSocketDataFromJson(String str) => MessageSocketData.fromJson(json.decode(str));

String messageSocketDataToJson(MessageSocketData data) => json.encode(data.toJson());

class MessageSocketData {
  MessageSocket? message;

  MessageSocketData({
    this.message,
  });

  factory MessageSocketData.fromJson(Map<String, dynamic> json) => MessageSocketData(
    message: json["message"] == null ? null : MessageSocket.fromJson(json["message"]),
  );

  Map<String, dynamic> toJson() => {
    "message": message?.toJson(),
  };

  @override
  String toString() {
    return 'MessageSocketData{message: $message}';
  }
}

class MessageSocket {
  int? id;
  String? text;
  String? type;
  dynamic filePath;
  bool? isLeadMessage;
  Sender? sender;
  bool? isMyMessage;
  String? createdAt;
  String? voiceDuration;
  Map<String, dynamic>? forwardedMessage;
  bool? isChanged;
  bool? isPinned;
  bool? isRead;
  

  MessageSocket({
    this.id,
    this.text,
    this.type,
    this.filePath,
    this.isLeadMessage,
    this.sender,
    this.isMyMessage,
    this.createdAt,
    this.voiceDuration,
    this.forwardedMessage,
    this.isChanged,
    this.isPinned,
    this.isRead,
  });

    @override
  String toString() {
    return 'MessageSocket{id: $id, text: $text, type: $type, filePath: $filePath, isLeadMessage: $isLeadMessage, sender: $sender, isMyMessage: $isMyMessage, createdAt: $createdAt, voiceDuration: $voiceDuration,forwardedMessage: $forwardedMessage,isChanged: $isChanged,isPinned: $isPinned,isRead: $isRead}';
  }

factory MessageSocket.fromJson(Map<String, dynamic> json) {
  return MessageSocket(
    id: json["id"],
    text: json["text"],
    type: json["type"],
    createdAt: json["created_at"] ?? '',
    filePath: json["file_path"],
    isLeadMessage: json["is_lead_message"] == false, 
    sender: json["sender"] == null ? null : Sender.fromJson(json["sender"]),
    isMyMessage: json["is_my_message"] ?? false, 
    voiceDuration: json["voice_duration"],
    forwardedMessage: json['forwarded_message'],
    isChanged: json['is_changed'] ?? false, 
    isPinned: json['is_pinned'] ?? false, 
    isRead: json['is_read'] ?? false, 

  );
}

  Map<String, dynamic> toJson() => {
    "id": id,
    "text": text,
    "type": type,
    "file_path": filePath,
    "is_lead_message": isLeadMessage,
    "sender": sender?.toJson(),
    "is_my_message": isMyMessage,
    "forwarded_message": forwardedMessage, 
    "is_changed": isChanged, 
    "is_pinned": isPinned, 
    "is_read": isRead, 
  };
}

class Sender {
  int? id;
  String? name;
  String? type;

  Sender({
    this.id,
    this.name,
    this.type,
  });

  factory Sender.fromJson(Map<String, dynamic> json) => Sender(
    id: json["id"],
    name: json["name"],
    type: json["type"],
  );


  @override
  String toString() {
    return 'Sender{id: $id, name: $name, type: $type}';
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "type": type,
  };
}
