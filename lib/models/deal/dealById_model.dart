import 'package:crm_task_manager/models/lead/lead_model.dart';
import 'package:crm_task_manager/models/lead/manager_model.dart';
import 'package:crm_task_manager/models/user/user_data_response.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

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
  final List<CustomFieldValue>
      customFieldValues; // ✅ НОВОЕ: для customFieldValues из API
  final List<DirectoryValue> directoryValues;
  final List<DealFiles> files;
  final List<DealUser>? users; // ✅ НОВОЕ: список пользователей сделки
  final int? reasonForRefusalId;
  final String? reasonForRefusalComment;
  final String? refusalReasonText;

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
    this.customFieldValues = const [], // ✅ НОВОЕ
    this.directoryValues = const [],
    this.files = const [],
    this.users, // ✅ НОВОЕ
    this.reasonForRefusalId,
    this.reasonForRefusalComment,
    this.refusalReasonText,
  });

  factory DealById.fromJson(Map<String, dynamic> json, int dealStatusId) {
    final usersList = SafeConverters.toList(json['users'])
        .where((item) => item != null)
        .map((userJson) => DealUser.fromJson(SafeConverters.toMap(userJson)))
        .toList();

    return DealById(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Без имени'),
      statusId: dealStatusId,
      startDate: SafeConverters.toStringOrNull(json['start_date']),
      endDate: SafeConverters.toStringOrNull(json['end_date']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      description: SafeConverters.toStringOrNull(json['description']),
      sum: SafeConverters.toStringOrNull(json['sum']),
      dealNumber: SafeConverters.toIntOrNull(json['deal_number']),
      manager: SafeConverters.toMapOrNull(json['manager']) != null
          ? ManagerData.fromJson(SafeConverters.toMap(json['manager']))
          : null,
      lead: SafeConverters.toMapOrNull(json['lead']) != null
          ? Lead.fromJson(
              SafeConverters.toMap(json['lead']),
              SafeConverters.toInt(SafeConverters.toMap(json['lead'])['status_id']),
            )
          : null,
      author: SafeConverters.toMapOrNull(json['author']) != null
          ? AuthorDeal.fromJson(SafeConverters.toMap(json['author']))
          : null,
      dealStatus: SafeConverters.toMapOrNull(json['deal_status']) != null
          ? DealStatusById.fromJson(SafeConverters.toMap(json['deal_status']))
          : null,
      dealStatuses: _parseList<DealStatusById>(
        json['deal_statuses'],
        (item) => DealStatusById.fromJson(SafeConverters.toMap(item)),
      ),
      customFieldValues: _parseList<CustomFieldValue>(
        json['customFieldValues'],
        (item) => CustomFieldValue.fromJson(SafeConverters.toMap(item)),
      ),
      directoryValues: _parseList<DirectoryValue>(
        json['directory_values'],
        (item) => DirectoryValue.fromJson(SafeConverters.toMap(item)),
      ),
      files: _parseList<DealFiles>(
        json['files'],
        (item) => DealFiles.fromJson(SafeConverters.toMap(item)),
      ),
      users: usersList.isEmpty ? null : usersList,
      reasonForRefusalId: SafeConverters.toIntOrNull(json['reason_for_refusal_id']),
      reasonForRefusalComment: SafeConverters.toStringOrNull(json['reason_for_refusal']),
      refusalReasonText: _extractRefusalReasonText(json['refusalReason']),
    );
  }

  /// Helper method to safely parse lists from JSON
  static List<T> _parseList<T>(dynamic json, T Function(dynamic) parser) {
    return SafeConverters.toList(json).map(parser).toList();
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
        'customFieldValues': customFieldValues.map((e) => e.toJson()).toList(),
        'directory_values': directoryValues.map((e) => e.toJson()).toList(),
        'files': files.map((e) => e.toJson()).toList(),
        'reason_for_refusal_id': reasonForRefusalId,
        'reason_for_refusal': reasonForRefusalComment,
        'refusalReason': refusalReasonText,
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
    List<CustomFieldValue>? customFieldValues,
    List<DirectoryValue>? directoryValues,
    List<DealFiles>? files,
    int? reasonForRefusalId,
    String? reasonForRefusalComment,
    String? refusalReasonText,
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
      customFieldValues: customFieldValues ?? this.customFieldValues,
      directoryValues: directoryValues ?? this.directoryValues,
      files: files ?? this.files,
      reasonForRefusalId: reasonForRefusalId ?? this.reasonForRefusalId,
      reasonForRefusalComment:
          reasonForRefusalComment ?? this.reasonForRefusalComment,
      refusalReasonText: refusalReasonText ?? this.refusalReasonText,
    );
  }
}

String? _extractRefusalReasonText(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) {
    return raw.trim().isEmpty ? null : raw.trim();
  }
  if (raw is Map<String, dynamic>) {
    final text = raw['text']?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
    final name = raw['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
  }
  return null;
}

class DealUser {
  final int id;
  final int? dealId;
  final int? userId;
  final String? createdAt;
  final String? updatedAt;
  final UserData? user; // Полная информация о пользователе

  DealUser({
    required this.id,
    this.dealId,
    this.userId,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory DealUser.fromJson(Map<String, dynamic> json) {
    return DealUser(
      id: SafeConverters.toInt(json['id']),
      dealId: SafeConverters.toIntOrNull(json['deal_id']),
      userId: SafeConverters.toIntOrNull(json['user_id']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      user: SafeConverters.toMapOrNull(json['user']) != null
          ? UserData.fromJson(SafeConverters.toMap(json['user']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deal_id': dealId,
      'user_id': userId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'user': user?.toJson(),
    };
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
      id: SafeConverters.toInt(json['id']),
      customFieldId: SafeConverters.toInt(json['custom_field_id']),
      organizationId: SafeConverters.toInt(json['organization_id']),
      modelId: SafeConverters.toInt(json['model_id']),
      modelType: SafeConverters.toSafeString(json['model_type']),
      value: SafeConverters.toSafeString(json['value']),
      type: SafeConverters.toSafeString(json['type'], defaultValue: 'string'),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      customField: SafeConverters.toMapOrNull(json['custom_field']) != null
          ? CustomFieldInfo.fromJson(SafeConverters.toMap(json['custom_field']))
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      isActive: SafeConverters.toInt(json['is_active']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
      type: SafeConverters.toSafeString(json['type'], defaultValue: 'deals'),
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      path: SafeConverters.toSafeString(json['path']),
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Не указан'),
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
      id: SafeConverters.toInt(json['id']),
      title: SafeConverters.toSafeString(json['title'], defaultValue: 'Без имени'),
      color: SafeConverters.toSafeString(json['color'], defaultValue: '#000000'),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
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
      id: SafeConverters.toInt(json['id']),
      entry: Entry.fromJson(SafeConverters.toMap(json['entry'])),
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
      id: SafeConverters.toInt(json['id']),
      directory: SafeConverters.toMapOrNull(json['directory']) != null
          ? DirectoryByDeal.fromJson(SafeConverters.toMap(json['directory']))
          : const DirectoryByDeal(id: 0, name: ''),
      values: parsedValues,
    );
  }

  static Map<String, dynamic> _parseValues(dynamic valuesRaw) {
    final map = SafeConverters.toMapOrNull(valuesRaw);
    if (map != null) {
      return map;
    }

    if (valuesRaw is List<dynamic>) {
      final result = <String, dynamic>{};
      for (final item in valuesRaw) {
        final itemMap = SafeConverters.toMapOrNull(item);
        if (itemMap != null) {
          final key = itemMap['key'];
          if (key is String) {
            result[key] = itemMap['value'] ?? '';
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
