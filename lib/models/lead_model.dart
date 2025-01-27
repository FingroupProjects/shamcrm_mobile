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
      id: json['id'] is int ? json['id'] : 0,
      name: json['name'] is String ? json['name'] : 'Без имени',
      source: json['source'] != null && json['source'] is Map<String, dynamic>
          ? Source.fromJson(json['source'])
          : null,
      messageAmount: json['message_amount'] is int ? json['message_amount'] : 0,
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      statusId: leadStatusId,
      manager: json['manager'] != null && json['manager'] is Map<String, dynamic>
              ? ManagerData.fromJson(json['manager'])
              : null,
      sourceLead: json['source'] != null && json['source'] is Map<String, dynamic>
              ? SourceLead.fromJson(json['source'])
              : null,
      organization: json['organization'] != null && json['organization'] is Map<String, dynamic>
          ? Organization.fromJson(json['organization'])
          : null,
      leadStatus: json['leadStatus'] != null
          ? LeadStatus.fromJson(json['leadStatus'])
          : null,
      phone: json['phone'] is String ? json['phone'] : '',
      inProgressDealsCount: json['in_progress_deals_count'] is int? ? json['in_progress_deals_count'] : 0,
      successefullyDealsCount: json['successful_deals_count'] is int? ? json['successful_deals_count'] : 0,
      failedDealsCount: json['failed_deals_count'] is int? ? json['failed_deals_count'] : 0,
      lastUpdate: json['last_update'] is int? ? json['last_update'] : 0,


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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
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
      isFailure: json['is_failure'] == true || json['is_failure'] == 1,
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
