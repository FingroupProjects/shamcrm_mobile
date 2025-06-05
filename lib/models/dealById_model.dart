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
  final DealStatusById? dealStatus;
  final List<DirectoryValue>? directoryValues;

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
    this.dealStatus,
    this.directoryValues,
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
      manager: json['manager'] != null ? ManagerData.fromJson(json['manager']) : null,
      lead: json['lead'] != null ? Lead.fromJson(json['lead'], json['lead']['status_id'] ?? 0) : null,
      author: json['author'] != null && json['author'] is Map<String, dynamic> ? AuthorDeal.fromJson(json['author']) : null,
      dealCustomFields: (json['deal_custom_fields'] as List<dynamic>?)?.map((field) => DealCustomFieldsById.fromJson(field)).toList() ?? [],
      dealStatus: json['deal_status'] != null ? DealStatusById.fromJson(json['deal_status']) : null,
      directoryValues: (json['directory_values'] as List<dynamic>?)?.map((dirValue) => DirectoryValue.fromJson(dirValue)).toList(),
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

class DirectoryValue {
  final int id;
  final Entry entry;

  DirectoryValue({
    required this.id,
    required this.entry,
  });

  factory DirectoryValue.fromJson(Map<String, dynamic> json) {
    return DirectoryValue(
      id: json['id'] ?? 0,
      entry: Entry.fromJson(json['entry']),
    );
  }
}

class Entry {
  final int id;
  final Directory directory;
  final Map<String, dynamic> values;

  Entry({
    required this.id,
    required this.directory,
    required this.values,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'] ?? 0,
      directory: Directory.fromJson(json['directory']),
      values: json['values'] ?? {},
    );
  }
}

class Directory {
  final int id;
  final String name;

  Directory({
    required this.id,
    required this.name,
  });

  factory Directory.fromJson(Map<String, dynamic> json) {
    return Directory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}