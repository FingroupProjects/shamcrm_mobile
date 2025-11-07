import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';

/// Main Deal model representing a deal by ID
class DealById {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? createdAt;
  final String? description;
  final String? sum;
  final int statusId;
  final int? dealNumber;
  final ManagerData? manager;
  final Lead? lead;
  final AuthorDeal? author;
  final DealStatusById? dealStatus;
  final List<DealStatusById> dealStatuses;
  final List<DealCustomFieldsById> dealCustomFields;
  final List<CustomFieldValue> customFieldValues; // ✅ НОВОЕ: для customFieldValues из API
  final List<DirectoryValue> directoryValues;
  final List<DealFiles> files;

  const DealById({
    required this.id,
    required this.name,
    required this.statusId,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.description,
    this.sum,
    this.dealNumber,
    this.manager,
    this.lead,
    this.author,
    this.dealStatus,
    this.dealStatuses = const [],
    this.dealCustomFields = const [],
    this.customFieldValues = const [], // ✅ НОВОЕ
    this.directoryValues = const [],
    this.files = const [],
  });

  factory DealById.fromJson(Map<String, dynamic> json, int dealStatusId) {
    return DealById(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Без имени',
      statusId: dealStatusId,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      createdAt: json['created_at'] as String?,
      description: json['description'] as String?,
      sum: json['sum'] as String?,
      dealNumber: json['deal_number'] as int?,
      manager: json['manager'] != null
          ? ManagerData.fromJson(json['manager'] as Map<String, dynamic>)
          : null,
      lead: json['lead'] != null
          ? Lead.fromJson(
        json['lead'] as Map<String, dynamic>,
        json['lead']['status_id'] as int? ?? 0,
      )
          : null,
      author: json['author'] != null && json['author'] is Map<String, dynamic>
          ? AuthorDeal.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      dealStatus: json['deal_status'] != null
          ? DealStatusById.fromJson(json['deal_status'] as Map<String, dynamic>)
          : null,
      dealStatuses: _parseList<DealStatusById>(
        json['deal_statuses'],
            (item) => DealStatusById.fromJson(item as Map<String, dynamic>),
      ),
      dealCustomFields: _parseList<DealCustomFieldsById>(
        json['deal_custom_fields'],
            (item) => DealCustomFieldsById.fromJson(item as Map<String, dynamic>),
      ),
      // ✅ НОВОЕ: парсим customFieldValues
      customFieldValues: _parseList<CustomFieldValue>(
        json['customFieldValues'],
            (item) => CustomFieldValue.fromJson(item as Map<String, dynamic>),
      ),
      directoryValues: _parseList<DirectoryValue>(
        json['directory_values'],
            (item) => DirectoryValue.fromJson(item as Map<String, dynamic>),
      ),
      files: _parseList<DealFiles>(
        json['files'],
            (item) => DealFiles.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  /// Helper method to safely parse lists from JSON
  static List<T> _parseList<T>(dynamic json, T Function(dynamic) parser) {
    if (json == null) return [];
    if (json is! List) return [];
    return json.map(parser).toList();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'start_date': startDate,
    'end_date': endDate,
    'created_at': createdAt,
    'description': description,
    'sum': sum,
    'status_id': statusId,
    'deal_number': dealNumber,
    'manager': manager?.toJson(),
    'lead': lead?.toJson(),
    'author': author?.toJson(),
    'deal_status': dealStatus?.toJson(),
    'deal_statuses': dealStatuses.map((e) => e.toJson()).toList(),
    'deal_custom_fields': dealCustomFields.map((e) => e.toJson()).toList(),
    'customFieldValues': customFieldValues.map((e) => e.toJson()).toList(),
    'directory_values': directoryValues.map((e) => e.toJson()).toList(),
    'files': files.map((e) => e.toJson()).toList(),
  };

  DealById copyWith({
    int? id,
    String? name,
    String? startDate,
    String? endDate,
    String? createdAt,
    String? description,
    String? sum,
    int? statusId,
    int? dealNumber,
    ManagerData? manager,
    Lead? lead,
    AuthorDeal? author,
    DealStatusById? dealStatus,
    List<DealStatusById>? dealStatuses,
    List<DealCustomFieldsById>? dealCustomFields,
    List<CustomFieldValue>? customFieldValues,
    List<DirectoryValue>? directoryValues,
    List<DealFiles>? files,
  }) {
    return DealById(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      sum: sum ?? this.sum,
      statusId: statusId ?? this.statusId,
      dealNumber: dealNumber ?? this.dealNumber,
      manager: manager ?? this.manager,
      lead: lead ?? this.lead,
      author: author ?? this.author,
      dealStatus: dealStatus ?? this.dealStatus,
      dealStatuses: dealStatuses ?? this.dealStatuses,
      dealCustomFields: dealCustomFields ?? this.dealCustomFields,
      customFieldValues: customFieldValues ?? this.customFieldValues,
      directoryValues: directoryValues ?? this.directoryValues,
      files: files ?? this.files,
    );
  }
}

/// ✅ НОВЫЙ КЛАСС: Represents custom field values from API response
class CustomFieldValue {
  final int id;
  final int customFieldId;
  final int organizationId;
  final int modelId;
  final String modelType;
  final String value;
  final String type;
  final String? createdAt;
  final String? updatedAt;
  final CustomFieldInfo? customField;

  const CustomFieldValue({
    required this.id,
    required this.customFieldId,
    required this.organizationId,
    required this.modelId,
    required this.modelType,
    required this.value,
    required this.type,
    this.createdAt,
    this.updatedAt,
    this.customField,
  });

  factory CustomFieldValue.fromJson(Map<String, dynamic> json) {
    return CustomFieldValue(
      id: json['id'] as int? ?? 0,
      customFieldId: json['custom_field_id'] as int? ?? 0,
      organizationId: json['organization_id'] as int? ?? 0,
      modelId: json['model_id'] as int? ?? 0,
      modelType: json['model_type'] as String? ?? '',
      value: json['value'] as String? ?? '',
      type: json['type'] as String? ?? 'string',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      customField: json['custom_field'] != null
          ? CustomFieldInfo.fromJson(json['custom_field'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'custom_field_id': customFieldId,
    'organization_id': organizationId,
    'model_id': modelId,
    'model_type': modelType,
    'value': value,
    'type': type,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'custom_field': customField?.toJson(),
  };
}

/// ✅ НОВЫЙ КЛАСС: Custom field information nested in CustomFieldValue
class CustomFieldInfo {
  final int id;
  final String name;
  final int isActive;
  final String? createdAt;
  final String? updatedAt;
  final String type;

  const CustomFieldInfo({
    required this.id,
    required this.name,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    required this.type,
  });

  factory CustomFieldInfo.fromJson(Map<String, dynamic> json) {
    return CustomFieldInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      isActive: json['is_active'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      type: json['type'] as String? ?? 'deals',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'is_active': isActive,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'type': type,
  };
}

/// Represents a file attached to a deal
class DealFiles {
  final int id;
  final String name;
  final String path;

  const DealFiles({
    required this.id,
    required this.name,
    required this.path,
  });

  factory DealFiles.fromJson(Map<String, dynamic> json) {
    return DealFiles(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
  };
}

/// Represents the author of a deal
class AuthorDeal {
  final int id;
  final String name;

  const AuthorDeal({
    required this.id,
    required this.name,
  });

  factory AuthorDeal.fromJson(Map<String, dynamic> json) {
    return AuthorDeal(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Не указан',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

/// Represents the status of a deal
class DealStatusById {
  final int id;
  final String title;
  final String color;
  final String? createdAt;
  final String? updatedAt;

  const DealStatusById({
    required this.id,
    required this.title,
    required this.color,
    this.createdAt,
    this.updatedAt,
  });

  factory DealStatusById.fromJson(Map<String, dynamic> json) {
    return DealStatusById(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Без имени',
      color: json['color'] as String? ?? '#000000',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'color': color,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is DealStatusById &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents custom fields for a deal (old format)
class DealCustomFieldsById {
  final int id;
  final String key;
  final String value;
  final String? type;

  const DealCustomFieldsById({
    required this.id,
    required this.key,
    required this.value,
    this.type,
  });

  factory DealCustomFieldsById.fromJson(Map<String, dynamic> json) {
    return DealCustomFieldsById(
      id: json['id'] as int? ?? 0,
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'value': value,
    if (type != null) 'type': type,
  };
}

/// Represents a directory value associated with a deal
class DirectoryValue {
  final int id;
  final Entry entry;

  const DirectoryValue({
    required this.id,
    required this.entry,
  });

  factory DirectoryValue.fromJson(Map<String, dynamic> json) {
    return DirectoryValue(
      id: json['id'] as int? ?? 0,
      entry: Entry.fromJson(json['entry'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'entry': entry.toJson(),
  };
}

/// Represents an entry in a directory
class Entry {
  final int id;
  final DirectoryByDeal directory;
  final Map<String, dynamic> values;

  const Entry({
    required this.id,
    required this.directory,
    required this.values,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    final parsedValues = _parseValues(json['values']);

    return Entry(
      id: json['id'] as int? ?? 0,
      directory: json['directory'] != null
          ? DirectoryByDeal.fromJson(json['directory'] as Map<String, dynamic>)
          : const DirectoryByDeal(id: 0, name: ''),
      values: parsedValues,
    );
  }

  static Map<String, dynamic> _parseValues(dynamic valuesRaw) {
    if (valuesRaw is Map<String, dynamic>) {
      return valuesRaw;
    }

    if (valuesRaw is List<dynamic>) {
      final result = <String, dynamic>{};
      for (final item in valuesRaw) {
        if (item is Map<String, dynamic>) {
          final key = item['key'];
          if (key is String) {
            result[key] = item['value'] ?? '';
          }
        }
      }
      return result;
    }

    return {};
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'directory': directory.toJson(),
    'values': values,
  };
}

/// Represents a directory associated with a deal
class DirectoryByDeal {
  final int id;
  final String name;

  const DirectoryByDeal({
    required this.id,
    required this.name,
  });

  factory DirectoryByDeal.fromJson(Map<String, dynamic> json) {
    return DirectoryByDeal(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}