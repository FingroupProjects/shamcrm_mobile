import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/source_model.dart';

class LeadById {
  final int id;
  final String name;
  final Source? source;
  final int messageAmount;
  final String? createdAt;
  final int statusId;
  final RegionData? region;
  final ManagerData? manager;
  final SourceLead? sourceLead;
  final String? birthday;
  final String? instagram;
  final String? facebook;
  final String? telegram;
  final String? phone;
  final String? email;
  final Author? author;
  final String? description;
  final LeadStatusById? leadStatus;

  LeadById({
    required this.id,
    required this.name,
    this.source,
    required this.messageAmount,
    this.createdAt,
    required this.statusId,
    this.region,
    this.manager,
    this.sourceLead,
    this.birthday,
    this.instagram,
    this.facebook,
    this.telegram,
    this.phone,
    this.email,
    this.author,
    this.description,
    this.leadStatus,
  });

  factory LeadById.fromJson(Map<String, dynamic> json, int leadStatusId) {
    return LeadById(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name'] is String ? json['name'] : 'Без имени',
      source: json['source'] != null && json['source'] is Map<String, dynamic>
          ? Source.fromJson(json['source'])
          : null,
      messageAmount: json['message_amount'] is int ? json['message_amount'] : 0,
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      statusId: leadStatusId,
      region: json['region'] != null && json['region'] is Map<String, dynamic>
          ? RegionData.fromJson(json['region'])
          : null,
      manager:
          json['manager'] != null && json['manager'] is Map<String, dynamic>
              ? ManagerData.fromJson(json['manager'])
              : null,
      sourceLead: json['source'] != null && json['source'] is Map<String, dynamic>
      ? SourceLead.fromJson(json['source'])
      : null,
      birthday: json['birthday'] is String ? json['birthday'] : '',
      instagram: json['insta_login'] is String ? json['insta_login'] : '',
      facebook: json['facebook_login'] is String ? json['facebook_login'] : '',
      telegram: json['tg_nick'] is String ? json['tg_nick'] : '',
      phone: json['phone'] is String ? json['phone'] : '',
      email: json['email'] is String ? json['email'] : '',
      author: json['author'] != null && json['author'] is Map<String, dynamic>
          ? Author.fromJson(json['author'])
          : null,
      description: json['description'] is String ? json['description'] : '',
      leadStatus: json['leadStatus'] != null &&
              json['leadStatus'] is Map<String, dynamic>
          ? LeadStatusById.fromJson(json['leadStatus'])
          : null,
    );
  }
}

class Author {
  final int id;
  final String name;

  Author({
    required this.id,
    required this.name,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Не указан',
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

class LeadStatusById {
  final int id;
  final String title;
  final String? color;

  LeadStatusById({
    required this.id,
    required this.title,
    this.color,
  });

  factory LeadStatusById.fromJson(Map<String, dynamic> json) {
    return LeadStatusById(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? 'Не указан',
      color: json['color'],
    );
  }
}
