import 'package:crm_task_manager/utils/safe_converters.dart';

class Notifications {
  final int id;
  final int notificationMessageId;
  final String type;
  final int modelId;
  final String modelType;
  final String message;
  final bool isRead;
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

  factory Notifications.fromJson(Map<String, dynamic> json) {
    return Notifications(
      id: SafeConverters.toInt(json['id']),
      notificationMessageId: SafeConverters.toInt(json['notification_message_id']),
      type: SafeConverters.toSafeString(json['type']),
      modelId: SafeConverters.toInt(json['model_id']),
      modelType: SafeConverters.toSafeString(json['model_type']),
      message: SafeConverters.toSafeString(json['message']),
      isRead: SafeConverters.toBool(json['is_read']),
      userId: SafeConverters.toInt(json['user_id']),
      createdAt: SafeConverters.toDateTime(json['created_at']),
      updatedAt: SafeConverters.toDateTime(json['updated_at']),
      organizationId: SafeConverters.toInt(json['organization_id']),
    );
  }

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
