import 'package:crm_task_manager/models/manager_model.dart';

class Deal {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? description;
  final String sum;
  final int statusId;
  final Manager? manager;
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
      manager: json['manager'] != null ? Manager.fromJson(json['manager']) : null,
      dealCustomFields: (json['deal_custom_fields'] as List<dynamic>?)
              ?.map((field) => DealCustomField.fromJson(field))
              .toList() ??
          [],
    );
  }
}

class DealCustomField {
  final int id;
  final String key;
  final String value;
  final String name;

  DealCustomField({
    required this.id,
    required this.key,
    required this.value,
    required this.name,
  });

  factory DealCustomField.fromJson(Map<String, dynamic> json) {
    return DealCustomField(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      value: json['value'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class DealStatus {
  final int id;
  final String title;
  final String color;
  final String? createdAt;
  final String? updatedAt;

  DealStatus({
    required this.id,
    required this.title,
    required this.color,
    this.createdAt,
    this.updatedAt,
  });

  factory DealStatus.fromJson(Map<String, dynamic> json) {
    return DealStatus(
      id: json['id'] is int ? json['id'] : 0,
      title: json['title'] is String ? json['title'] : 'Без имени',
      color: json['color'] is String ? json['color'] : '#000',
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      updatedAt: json['updated_at'] is String ? json['updated_at'] : null,
    );
  }
}