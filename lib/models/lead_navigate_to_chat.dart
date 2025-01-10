import 'package:crm_task_manager/models/lead_model.dart';

class LeadNavigateChat {
  final int id;
  final Source channel;
  final Lead lead;
  final String type;
  final bool canSendMessage;

  LeadNavigateChat({
    required this.id,
    required this.channel,
    required this.lead,
    required this.type,
    required this.canSendMessage,
  });

  factory LeadNavigateChat.fromJson(Map<String, dynamic> json) {
    return LeadNavigateChat(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      channel:
          json['channel'] != null && json['channel'] is Map<String, dynamic>
              ? Source.fromJson(json['channel'])
              : Source(name: ''),
      lead: json['lead'] != null && json['lead'] is Map<String, dynamic>
          ? Lead.fromJson(json['lead'], json['lead_status_id'] ?? 0)
          : Lead(id: 0, name: 'Без имени', messageAmount: 0, statusId: 0),
      type: json['type'] is String ? json['type'] : '',
      canSendMessage: json["can_send_message"] ?? false,
     
);
  }
}
