import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';

class Lead {
  final int id;
  final String name;
  final Source? source;
  final int messageAmount;
  final String? createdAt;
  final int statusId;
  final Region? region;
  final Manager? manager;
  final String? birthday;
  final String? instagram;
  final String? facebook;
  final String? telegram;
  final String? phone;
  final String? description;
  final LeadStatus? leadStatus;

  Lead({
    required this.id,
    required this.name,
    this.source,
    required this.messageAmount,
    this.createdAt,
    required this.statusId,
    this.region,
    this.manager,
    this.birthday,
    this.instagram,
    this.facebook,
    this.telegram,
    this.phone,
    this.description,
    this.leadStatus,
  });

  factory Lead.fromJson(Map<String, dynamic> json, int leadStatusId) {
    return Lead(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name'] is String ? json['name'] : 'Без имени',
      source: json['source'] != null && json['source'] is Map<String, dynamic>
          ? Source.fromJson(json['source'])
          : null,
      messageAmount: json['message_amount'] is int ? json['message_amount'] : 0,
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      statusId: leadStatusId,
      region: json['region'] != null && json['region'] is Map<String, dynamic>
          ? Region.fromJson(json['region'])
          : null,
      manager:
          json['manager'] != null && json['manager'] is Map<String, dynamic>
              ? Manager.fromJson(json['manager'])
              : null,
      birthday: json['birthday'] is String ? json['birthday'] : '',
      instagram: json['insta_login'] is String ? json['insta_login'] : '',
      facebook: json['facebook_login'] is String ? json['facebook_login'] : '',
      telegram: json['tg_nick'] is String ? json['tg_nick'] : '',
      phone: json['phone'] is String ? json['phone'] : '',
      description: json['description'] is String ? json['description'] : '',
      // leadStatus: json['leadStatus'] != null &&
      //         json['leadStatus'] is Map<String, dynamic>
      //     ? LeadStatus.fromJson(json['leadStatus'])
      //     : null,
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
  final String? color;

  LeadStatus({
    required this.id,
    required this.title,
    this.color,
  });

  factory LeadStatus.fromJson(Map<String, dynamic> json) {
    return LeadStatus(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? 'Не указан', 
      color: json['color'],
    );
  }
}
