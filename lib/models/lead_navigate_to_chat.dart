import 'package:crm_task_manager/models/lead_model.dart';

class LeadNavigateChat {
  final int id;
  final Source channel;
  final Lead lead;
  final String type;
  final bool canSendMessage;
  final Integration? integration;

  LeadNavigateChat({
    required this.id,
    required this.channel,
    required this.lead,
    required this.type,
    required this.canSendMessage,
    this.integration,
  });

  factory LeadNavigateChat.fromJson(Map<String, dynamic> json) {
    print('LeadNavigateChat: Parsing JSON for chat ID: ${json['id']}, Integration: ${json['integration']}');
    return LeadNavigateChat(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      channel: json['channel'] != null && json['channel'] is Map<String, dynamic>
          ? Source.fromJson(json['channel'])
          : Source(name: ''),
      lead: json['lead'] != null && json['lead'] is Map<String, dynamic>
          ? Lead.fromJson(json['lead'], json['lead_status_id'] ?? 0)
          : Lead(id: 0, name: 'Без имени', statusId: 0),
      type: json['type'] is String ? json['type'] : '',
      canSendMessage: json["can_send_message"] ?? false,
      integration: json['integration'] != null && json['integration'] is Map<String, dynamic>
          ? Integration.fromJson(json['integration'])
          : null,
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
    print('Integration: Parsing JSON: $json');
    return Integration(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
    );
  }
}