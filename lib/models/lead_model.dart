import 'package:crm_task_manager/models/region_model.dart';

class Lead {
  final int id;
  final String name;
  final Source? source; 
  final int messageAmount;
  final String? createdAt;
  final int statusId;
  final Region? region;
  final String? birthday;
  final String? instagram;
  final String? facebook;
  final String? telegram;
  final String? phone;
  final String? description;

  Lead({
    required this.id,
    required this.name,
    this.source,
    required this.messageAmount,
    this.createdAt,
    required this.statusId,
    this.region,
    this.birthday,
    this.instagram,
    this.facebook,
    this.telegram,
    this.phone,
    this.description,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name'] is String ? json['name'] : 'Без имени',
      source: json['source'] != null && json['source'] is Map<String, dynamic>
          ? Source.fromJson(json['source'])
          : null,
      messageAmount: json['message_amount'] is int ? json['message_amount'] : 0,
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      statusId: json['leadStatus'] != null &&
              json['leadStatus'] is Map<String, dynamic>
          ? (json['leadStatus']['id'] is int ? json['leadStatus']['id'] : 0)
          : 0,
      region: json['region'] != null && json['region'] is Map<String, dynamic>
          ? Region.fromJson(json['region'])
          : null, // Ensure region is processed correctly
      birthday: json['birthday'] is String ? json['birthday'] : 'Не указано',
      instagram:
          json['insta_login'] is String ? json['insta_login'] : 'Не указано',
      facebook: json['facebook_login'] is String
          ? json['facebook_login']
          : 'Не указано',
      telegram: json['tg_nick'] is String ? json['tg_nick'] : 'Не указано',
      phone: json['phone'] is String ? json['phone'] : 'Не указано',
      description:
          json['description'] is String ? json['description'] : 'Не указано',
    );
  }
}

class Source {
  final String name;

  Source({required this.name});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      name: json['name'],
    );
  }
}

class LeadStatus {
  final int id;
  final String title;
  final int leadsCount;

  LeadStatus({
    required this.id,
    required this.title,
    required this.leadsCount,
  });

  factory LeadStatus.fromJson(Map<String, dynamic> json) {
    return LeadStatus(
      id: json['id'],
      title: json['title'],
      leadsCount: json['leads_count'],
    );
  }
}
