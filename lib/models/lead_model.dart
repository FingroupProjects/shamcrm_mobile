import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/organization_model.dart';
import 'package:crm_task_manager/models/source_model.dart';

class Lead {
  final int id;
  final String name;
  final Source? source;
  final int messageAmount;
  final String? createdAt;
  final int statusId;
  final ManagerData? manager;
  final SourceLead? sourceLead;
  final LeadStatus? leadStatus;
  final Organization? organization;
  final String? phone;
  final int? inProgressDealsCount;
  final int? successefullyDealsCount;
  final int? failedDealsCount;
  final int? lastUpdate;

  Lead({
    required this.id,
    required this.name,
    this.source,
    required this.messageAmount,
    this.createdAt,
    required this.statusId,
    this.manager,
    this.sourceLead,
    this.leadStatus,
    this.organization,
    this.phone,
    this.inProgressDealsCount,
    this.successefullyDealsCount,
    this.failedDealsCount,
    this.lastUpdate,
  });

  factory Lead.fromJson(Map<String, dynamic> json, int leadStatusId) {
    return Lead(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Без имени',
      source: json['source'] != null ? Source.fromJson(json['source']) : null,
      messageAmount: json['message_amount'] ?? 0,
      createdAt: json['created_at']?.toString(),
      statusId: leadStatusId,
      manager: json['manager'] != null ? ManagerData.fromJson(json['manager']) : null,
      sourceLead: json['source'] != null ? SourceLead.fromJson(json['source']) : null,
      organization: json['organization'] != null ? Organization.fromJson(json['organization']) : null,
      leadStatus: json['leadStatus'] != null ? LeadStatus.fromJson(json['leadStatus']) : null,
      phone: json['phone']?.toString() ?? '',
      inProgressDealsCount: json['in_progress_deals_count'],
      successefullyDealsCount: json['successful_deals_count'],
      failedDealsCount: json['failed_deals_count'],
      lastUpdate: json['last_update'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'source': source?.toJson(),
      'message_amount': messageAmount,
      'created_at': createdAt,
      'status_id': statusId,
      'manager': manager?.toJson(),
      'sourceLead': sourceLead?.toJson(),
      'organization': organization?.toJson(),
      'leadStatus': leadStatus?.toJson(),
      'phone': phone,
      'in_progress_deals_count': inProgressDealsCount,
      'successful_deals_count': successefullyDealsCount,
      'failed_deals_count': failedDealsCount,
      'last_update': lastUpdate,
    };
  }
}
class Author {
  final int id;
  final String name;
  final String? lastname;
  final String? login;
  final String? email;
  final String? phone;
  final dynamic image;  // Changed from String? to dynamic to handle both string and map
  final String? lastSeen;
  final String? deletedAt;
  final String? telegramUserId;
  final String? jobTitle;
  final bool? online;
  final String? fullName;

  Author({
    required this.id,
    required this.name,
    this.lastname,
    this.login,
    this.email,
    this.phone,
    this.image,
    this.lastSeen,
    this.deletedAt,
    this.telegramUserId,
    this.jobTitle,
    this.online,
    this.fullName,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      lastname: json['lastname'],
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
      image: json['image'],  // Accept image as-is without type conversion
      lastSeen: json['last_seen'],
      deletedAt: json['deleted_at'],
      telegramUserId: json['telegram_user_id']?.toString(),
      jobTitle: json['job_title'],
      online: json['online'],
      fullName: json['full_name'],
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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}

class LeadStatus {
  final int id;
  final String title;
  final String? color;
  final String? lead_status_id;
  final int leadsCount;
  final List<Lead> leads; // Добавляем список лидов
  final bool isSuccess;
  final int position;
  final bool isFailure;
  LeadStatus({
    required this.id,
    required this.title,
    this.color,
    this.lead_status_id,
    required this.leadsCount,
    this.leads = const [], // По умолчанию пустой список
    required this.isSuccess,
    required this.position,
    required this.isFailure,
  });

  factory LeadStatus.fromJson(Map<String, dynamic> json) {
    return LeadStatus(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? '',
      color: json['color'],
      lead_status_id: json['lead_status_id'] ?? null,
      leadsCount: json['leads_count'] ?? 0,
      isSuccess: json['is_success'] == true || json['is_success'] == 1,
      position: json['position'] ?? 0,
      isFailure: json['isx`_failure'] == true || json['is_failure'] == 1,
      leads: (json['leads'] as List<dynamic>?)
              ?.map((lead) => Lead.fromJson(lead, json['id']))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color,
      'lead_status_id': lead_status_id,
      'leads': leads.map((lead) => lead.toJson()).toList(),
      'is_success': isSuccess,
      'position': position,
      'is_failure': isFailure,
    };
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
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
    };
  }
}
