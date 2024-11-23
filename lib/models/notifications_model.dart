class Notifications {
  final int id;
  final int notificationMessageId;
  final String type;
  final int modelId;
  final String modelType;
  final String message;
  final int isRead;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int organizationId;

  Notifications({
    required this.id,
    required this.notificationMessageId,
    required this.type,
    required this.modelId,
    required this.modelType,
    required this.message,
    required this.isRead,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.organizationId,
  });

  // Метод для десериализации из JSON
  factory Notifications.fromJson(Map<String, dynamic> json) {
    return Notifications(
      id: json['id'] as int,
      notificationMessageId: json['notification_message_id'] as int,
      type: json['type'] as String,
      modelId: json['model_id'] as int,
      modelType: json['model_type'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as int,
      userId: json['user_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      organizationId: json['organization_id'] as int,
    );
  }

  // Метод для сериализации в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notification_message_id': notificationMessageId,
      'type': type,
      'model_id': modelId,
      'model_type': modelType,
      'message': message,
      'is_read': isRead,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'organization_id': organizationId,
    };
  }
}
