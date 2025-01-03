import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/organization_model.dart';
import 'package:crm_task_manager/models/region_model.dart';
import 'package:crm_task_manager/models/source_model.dart';

class Lead {
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
  final String? whatsApp;
  final String? email;
  final Author? author;
  final String? description;
  final LeadStatus? leadStatus;
  final Organization? organization;
  final List<LeadCustomField> leadCustomFields;

  Lead({
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
    this.whatsApp,
    this.email,
    this.author,
    this.description,
    this.leadStatus,
    this.organization,
    required this.leadCustomFields,
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
          ? RegionData.fromJson(json['region'])
          : null,
      manager:
          json['manager'] != null && json['manager'] is Map<String, dynamic>
              ? ManagerData.fromJson(json['manager'])
              : null,
      sourceLead:
          json['source'] != null && json['source'] is Map<String, dynamic>
              ? SourceLead.fromJson(json['source'])
              : null,
      birthday: json['birthday'] is String ? json['birthday'] : '',
      instagram: json['insta_login'] is String ? json['insta_login'] : '',
      facebook: json['facebook_login'] is String ? json['facebook_login'] : '',
      telegram: json['tg_nick'] is String ? json['tg_nick'] : '',
      phone: json['phone'] is String ? json['phone'] : '',
      whatsApp: json['wa_phone'] is String ? json['wa_phone'] : '',
      email: json['email'] is String ? json['email'] : '',
      author: json['author'] != null && json['author'] is Map<String, dynamic>
          ? Author.fromJson(json['author'])
          : null,
      description: json['description'] is String ? json['description'] : '',
      organization: json['organization'] != null &&
              json['organization'] is Map<String, dynamic>
          ? Organization.fromJson(json['organization'])
          : null,
      leadStatus: json['leadStatus'] != null
        ? LeadStatus.fromJson(json['leadStatus'])
        : null, 
      leadCustomFields: (json['lead_custom_fields'] as List<dynamic>?)
              ?.map((field) => LeadCustomField.fromJson(field))
              .toList() ??
          [],
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
      name: json['name'] ?? 'Не указано',
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
  final String? lead_status_id;

  LeadStatus({
    required this.id,
    required this.title,
    this.color,
    this.lead_status_id,
  });

  factory LeadStatus.fromJson(Map<String, dynamic> json) {
    return LeadStatus(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? '',
      color: json['color'],
      lead_status_id: json['lead_status_id'] ?? null,
    );
  }
}

class LeadCustomField {
  final int id;
  final String key;
  final String value;

  LeadCustomField({
    required this.id,
    required this.key,
    required this.value,
  });

  factory LeadCustomField.fromJson(Map<String, dynamic> json) {
    return LeadCustomField(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
  }
}
