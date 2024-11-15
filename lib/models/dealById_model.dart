import 'package:crm_task_manager/models/currency_model.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';

class DealById {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? description;
  final String sum;
  final int statusId;
  final Manager? manager;
  final Currency? currency;
  final Lead? lead;
  final List<DealCustomFieldsById> dealCustomFields;

  DealById({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.description,
    required this.sum,
    required this.statusId,
    this.manager,
    this.currency,
    this.lead,
    required this.dealCustomFields,
  });

  factory DealById.fromJson(Map<String, dynamic> json, int dealStatusId) {
    return DealById(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Без имени',
      startDate: json['start_date'],
      endDate: json['end_date'],
      description: json['description'] ?? '',
      sum: json['sum'] ?? '0.00',
      statusId: dealStatusId,
      manager:
          json['manager'] != null ? Manager.fromJson(json['manager']) : null,
      currency:
          json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      lead: json['lead'] != null ? Lead.fromJson(json['lead'], json['lead']['status_id'] ?? 0) : null,
      dealCustomFields: (json['deal_custom_fields'] as List<dynamic>?)
              ?.map((field) => DealCustomFieldsById.fromJson(field))
              .toList() ??
          [],
    );
  }
}

class DealCustomFieldsById {
  final int id;
  final String key;
  final String value;

  DealCustomFieldsById({
    required this.id,
    required this.key,
    required this.value,
  });

  factory DealCustomFieldsById.fromJson(Map<String, dynamic> json) {
    return DealCustomFieldsById(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

class DealStatusById {
  final int id;
  final String title;
  final String color;
  final String? createdAt;
  final String? updatedAt;

  DealStatusById({
    required this.id,
    required this.title,
    required this.color,
    this.createdAt,
    this.updatedAt,
  });

  factory DealStatusById.fromJson(Map<String, dynamic> json) {
    return DealStatusById(
      id: json['id'] is int ? json['id'] : 0,
      title: json['title'] is String ? json['title'] : 'Без имени',
      color: json['color'] is String ? json['color'] : '#000',
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      updatedAt: json['updated_at'] is String ? json['updated_at'] : null,
    );
  }
}
