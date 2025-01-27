import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';

class Deal {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? description;
  final String sum;
  final int statusId;
  final ManagerData? manager;
  final Lead? lead;
  final DealStatus? dealStatus;
  final List<DealCustomField> dealCustomFields;

  Deal({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.description,
    required this.sum,
    required this.statusId,
    this.manager,
    this.lead,
    this.dealStatus,
    required this.dealCustomFields,
  });

  factory Deal.fromJson(Map<String, dynamic> json, int dealStatusId) {
    return Deal(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Без имени',
      startDate: json['start_date'],
      endDate: json['end_date'],
      description: json['description'] ?? '',
      sum: json['sum'] ?? '0.00',
      statusId: dealStatusId,
      dealStatus: json['deal_status'] != null
          ? DealStatus.fromJson(json['deal_status'])
          : null,
      manager: json['manager'] != null
          ? ManagerData.fromJson(json['manager'])
          : null,
      lead: json['lead'] != null
          ? Lead.fromJson(json['lead'], json['lead']['status_id'] ?? 0)
          : null,
      dealCustomFields: (json['deal_custom_fields'] as List<dynamic>?)
              ?.map((field) => DealCustomField.fromJson(field))
              .toList() ??
          [],
    );
  }

  // Method to convert Deal object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
      'description': description,
      'sum': sum,
      'status_id': statusId,
      'manager': manager?.toJson(),
      'lead': lead?.toJson(),
      'deal_status': dealStatus?.toJson(),
      'deal_custom_fields':
          dealCustomFields.map((field) => field.toJson()).toList(),
    };
  }
}

class DealCustomField {
  final int id;
  final String key;
  final String value;

  DealCustomField({
    required this.id,
    required this.key,
    required this.value,
  });

  factory DealCustomField.fromJson(Map<String, dynamic> json) {
    return DealCustomField(
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

class DealStatus {
  final int id;
  final String title;
  final String color;
  final int organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int day;
  final bool isSuccess;
  final int position;
  final bool isFailure;
  final int dealsCount;

  DealStatus({
    required this.id,
    required this.title,
    required this.color,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
    required this.day,
    required this.isSuccess,
    required this.position,
    required this.isFailure,
    required this.dealsCount,
  });

  factory DealStatus.fromJson(Map<String, dynamic> json) {
    return DealStatus(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      color: json['color'] ?? '#000',
      organizationId: json['organization_id'] ?? 0,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      day: json['day'] ?? 0,
      isSuccess: json['is_success'] == true || json['is_success'] == 1,
      position: json['position'] ?? 0,
      isFailure: json['is_failure'] == true || json['is_failure'] == 1,
      dealsCount: json['deals_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color,
      'organization_id': organizationId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'day': day,
      'is_success': isSuccess,
      'position': position,
      'is_failure': isFailure,
      'deals_count': dealsCount,
    };
  }
}
