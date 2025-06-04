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
  final bool outDated;
  final String? createdAt;

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
    required this.outDated,
    this.createdAt,
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
            .toList() ?? [],
    outDated: json['out_dated'] ?? false,
    createdAt: json['created_at'] 
  );
}


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
      'deal_custom_fields': dealCustomFields.map((field) => field.toJson()).toList(),
      'out_dated': outDated,
      'created_at': createdAt,

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
  final String? createdAt;
  final String? updatedAt;
  final int dealsCount;
  final int? day;
  final bool isSuccess;
  final bool isFailure;

  DealStatus({
    required this.id,
    required this.title,
    required this.color,
    this.createdAt,
    this.updatedAt,
    required this.dealsCount,
    this.day,
    required this.isSuccess,
    required this.isFailure,
  });

factory DealStatus.fromJson(Map<String, dynamic> json) {

  return DealStatus(
    id: json['id'] as int? ?? 0,
    title: json['title'] as String? ?? 'Без имени',
    color: json['color'] as String? ?? '#000',
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
    day: json['day'] as int?,
    dealsCount: json['deals_count'] as int? ?? 0,
    isSuccess: json['is_success'] as bool? ?? false,
    isFailure: json['is_failure'] as bool? ?? false,
  );
}


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deals_count': dealsCount,
      'day': day,
      'is_success': isSuccess,
      'is_failure': isFailure,
    };
  }
}
