import 'package:crm_task_manager/models/chats_model.dart';

class ChatsGetId {
  final int id;
  final Channel? channel;
  // final Task? task;
  final Group? group;
  final ChatUser? user;
  final bool canSendMessage;
  final String type;
  final int unreadCount;
  final String? referralBody;
  final Integration? integration;

  ChatsGetId({
    required this.id,
    this.channel,
    // this.task,
    this.group,
    this.user,
    required this.canSendMessage,
    required this.type,
    required this.unreadCount,
    this.referralBody,
    this.integration,
  });

  factory ChatsGetId.fromJson(Map<String, dynamic> json) {
    return ChatsGetId(
      id: json['id'] ?? 0,
      channel: json['channel'] != null ? Channel.fromJson(json['channel']) : null,
      // task: json['task'] != null ? Task.fromJson(json['task'], json['task']['status_id'] ?? 0) : null,
      group: json['group'] != null ? Group.fromJson(json['group']) : null,
      user: json['user'] != null ? ChatUser.fromJson({'participant': json['user']}) : null,
      canSendMessage: json['can_send_message'] ?? false,
      type: json['type'] ?? '',
      unreadCount: json['unread_count'] ?? 0,
      referralBody: json['referral_body'],
      integration: json['integration'] != null ? Integration.fromJson(json['integration']) : null,
    );
  }
}

class Channel {
  final int id;
  final String name;
  final int? organizationId;

  Channel({
    required this.id,
    required this.name,
    this.organizationId,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      organizationId: json['organization_id'],
    );
  }
}

class Integration {
  final int id;
  final String name;
  final String username;

  Integration({
    required this.id,
    required this.name,
    required this.username,
  });

  factory Integration.fromJson(Map<String, dynamic> json) {
    return Integration(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
    );
  }
}