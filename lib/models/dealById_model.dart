import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';

class DealById {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? createdAt;
  final String? description;
  final String sum;
  final int statusId;
  final ManagerData? manager;
  final Lead? lead;
  final AuthorDeal? author;
  final List<DealCustomFieldsById> dealCustomFields;

  DealById({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.description,
    required this.sum,
    required this.statusId,
    this.manager,
    this.lead,
    this.author,
    required this.dealCustomFields,
  });

  factory DealById.fromJson(Map<String, dynamic> json, int dealStatusId) {
    return DealById(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Без имени',
      startDate: json['start_date'],
      endDate: json['end_date'],
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      description: json['description'] ?? '',
      sum: json['sum'] ?? '',
      statusId: dealStatusId,
      manager:
          json['manager'] != null ? ManagerData.fromJson(json['manager']) : null,
      lead: json['lead'] != null ? Lead.fromJson(json['lead'], json['lead']['status_id'] ?? 0) : null,
      author: json['author'] != null && json['author'] is Map<String, dynamic>
          ? AuthorDeal.fromJson(json['author'])
          : null,
      dealCustomFields: (json['deal_custom_fields'] as List<dynamic>?)
              ?.map((field) => DealCustomFieldsById.fromJson(field))
              .toList() ??
          [],
    );
  }
}

class AuthorDeal {
  final int id;
  final String name;

  AuthorDeal({
    required this.id,
    required this.name,
  });

  factory AuthorDeal.fromJson(Map<String, dynamic> json) {
    return AuthorDeal(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Не указан',
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
