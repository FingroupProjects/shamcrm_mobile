import 'package:crm_task_manager/models/deal/dealById_model.dart';
import 'package:crm_task_manager/models/deal/deal_model.dart';
import 'package:crm_task_manager/models/task/project_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

class TaskById {
  final int id;
  final int taskNumber;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? createdAt;
  final String? description;
  final int statusId;
  final TaskStatusById? taskStatus;
  final String? color;
  final Project? project;
  final DealById? deal;
  final List<UserById>? user;
  final int priority;
  final ChatById? chat;
  final AuthorTask? author;
  // final List<TaskCustomFieldsById> taskCustomFields;
  final List<CustomFieldsById> customFields;
  final String? taskFile;
  final int isFinished;
  final List<TaskFiles>? files;
  final List<DirectoryValues>? directoryValues; // Новое поле
  final int? reasonForRefusalId;
  final String? reasonForRefusalComment;
  final String? refusalReasonText;

  TaskById({
    required this.id,
    required this.taskNumber,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.createdAt,
    this.description,
    required this.statusId,
    this.taskStatus,
    this.color,
    this.project,
    this.deal,
    this.user,
    required this.priority,
    this.chat,
    this.author,
    required this.customFields,
    this.taskFile,
    this.files,
    required this.isFinished,
    this.directoryValues, // Инициализация нового поля
    this.reasonForRefusalId,
    this.reasonForRefusalComment,
    this.refusalReasonText,
  });

  factory TaskById.fromJson(Map<String, dynamic> json, int taskStatusId) {
    return TaskById(
      id: SafeConverters.toInt(json['id']),
      taskNumber: SafeConverters.toInt(json['task_number']),
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Без имени'),
      startDate: SafeConverters.toStringOrNull(json['from']),
      endDate: SafeConverters.toStringOrNull(json['to']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      description: SafeConverters.toSafeString(json['description']),
      statusId: taskStatusId,
      priority: SafeConverters.toInt(json['priority_level']),
      taskStatus: SafeConverters.toMapOrNull(json['taskStatus']) != null
          ? TaskStatusById.fromJson(SafeConverters.toMap(json['taskStatus']))
          : null,
      project: SafeConverters.toMapOrNull(json['project']) != null
          ? Project.fromJson(SafeConverters.toMap(json['project']))
          : null,
      user: json['users'] != null
          ? SafeConverters.toList(json['users'])
              .map((userJson) => UserById.fromJson(SafeConverters.toMap(userJson)))
              .toList()
          : null,
      deal: SafeConverters.toMapOrNull(json['deal']) != null
          ? DealById.fromJson(SafeConverters.toMap(json['deal']), 0)
          : null,
      color: SafeConverters.toStringOrNull(json['color']),
      taskFile: SafeConverters.toStringOrNull(json['file']),
      files: json['files'] != null
          ? SafeConverters.toList(json['files'])
              .map((fileJson) => TaskFiles.fromJson(SafeConverters.toMap(fileJson)))
              .toList()
          : null,
      chat: SafeConverters.toMapOrNull(json['chat']) != null
          ? ChatById.fromJson(SafeConverters.toMap(json['chat']))
          : null,
      author: SafeConverters.toMapOrNull(json['author']) != null
          ? AuthorTask.fromJson(SafeConverters.toMap(json['author']))
          : null,
      customFields: SafeConverters.toList(json['custom_fields'])
          .map((field) => CustomFieldsById.fromJson(SafeConverters.toMap(field)))
          .toList(),
      isFinished: SafeConverters.toInt(json['is_finished']),
      directoryValues: json['directory_values'] != null
          ? SafeConverters.toList(json['directory_values'])
              .map((dirJson) => DirectoryValues.fromJson(SafeConverters.toMap(dirJson)))
              .toList()
          : null,
      reasonForRefusalId: SafeConverters.toIntOrNull(json['reason_for_refusal_id']),
      reasonForRefusalComment: SafeConverters.toStringOrNull(json['reason_for_refusal']),
      refusalReasonText: _extractRefusalReasonText(json['refusalReason']),
    );
  }
}

String? _extractRefusalReasonText(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) {
    final text = raw.trim();
    return text.isEmpty ? null : text;
  }
  final map = SafeConverters.toMapOrNull(raw);
  if (map != null) {
    final text = SafeConverters.toStringOrNull(map['text'])?.trim();
    if (text != null && text.isNotEmpty) return text;
    final name = SafeConverters.toStringOrNull(map['name'])?.trim();
    if (name != null && name.isNotEmpty) return name;
  }
  return null;
}

class AuthorTask {
  final int id;
  final String name;
  final String? lastname;
  final String? fullName;

  AuthorTask({
    required this.id,
    required this.name,
    this.lastname,
    this.fullName,
  });

  factory AuthorTask.fromJson(Map<String, dynamic> json) {
    return AuthorTask(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Не указан'),
      lastname: SafeConverters.toStringOrNull(json['lastname']),
      fullName: SafeConverters.toStringOrNull(json['full_name']),
    );
  }
}

class TaskFiles {
  final int id;
  final String name;
  final String path;

  TaskFiles({
    required this.id,
    required this.name,
    required this.path,
  });

  factory TaskFiles.fromJson(Map<String, dynamic> json) {
    return TaskFiles(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      path: SafeConverters.toSafeString(json['path']),
    );
  }
}

class CustomFieldsById {
  final int id;
  final String name;
  final String value;
  final String type;

  CustomFieldsById({
    required this.id,
    required this.name,
    required this.value,
    required this.type,
  });

  factory CustomFieldsById.fromJson(Map<String, dynamic> json) {
    return CustomFieldsById(
      id: SafeConverters.toInt(json['field_id']),
      name: SafeConverters.toSafeString(json['name']),
      value: SafeConverters.toSafeString(json['value']),
      type: SafeConverters.toSafeString(json['type']),
    );
  }
}

class ChatById {
  final int id;
  final String? lead;
  final String type;
  final String? user;
  final bool canSendMessage;

  ChatById({
    required this.id,
    this.lead,
    required this.type,
    this.user,
    required this.canSendMessage,
  });

  factory ChatById.fromJson(Map<String, dynamic> json) {
    return ChatById(
      id: SafeConverters.toInt(json['id']),
      lead: SafeConverters.toStringOrNull(json['lead']),
      type: SafeConverters.toSafeString(json['type'], defaultValue: 'unknown'),
      user: SafeConverters.toStringOrNull(json['user']),
      canSendMessage: SafeConverters.toBool(json['can_send_message']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead': lead,
      'type': type,
      'user': user,
      'can_send_message': canSendMessage,
    };
  }
}

class UserById {
  final int id;
  final String name;
  final String lastname;

  final String email;
  final String phone;

  UserById({
    required this.id,
    required this.name,
    required this.lastname,
    required this.email,
    required this.phone,
  });

  factory UserById.fromJson(Map<String, dynamic> json) {
    return UserById(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      lastname: SafeConverters.toSafeString(json['lastname']),
      email: SafeConverters.toSafeString(json['email']),
      phone: SafeConverters.toSafeString(json['phone']),
    );
  }
}

class TaskFileById {
  final String name;
  final String size;

  TaskFileById({required this.name, required this.size});

  Map<String, dynamic> toJson() => {
        "name": name,
        "size": size,
      };

  factory TaskFileById.fromJson(Map<String, dynamic> json) => TaskFileById(
        name: SafeConverters.toSafeString(json["name"]),
        size: SafeConverters.toSafeString(json["size"]),
      );
}

class TaskStatusById {
  final int id;
  final TaskStatusNameById? taskStatus; // Make taskStatus nullable
  final String color;

  TaskStatusById({
    required this.id,
    this.taskStatus, // Allow null
    required this.color,
  });

  factory TaskStatusById.fromJson(Map<String, dynamic> json) {
    return TaskStatusById(
      id: SafeConverters.toInt(json['id']),
      taskStatus: SafeConverters.toMapOrNull(json['taskStatus']) != null
          ? TaskStatusNameById.fromJson(SafeConverters.toMap(json['taskStatus']))
          : null,
      color: SafeConverters.toSafeString(json['color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskStatus': taskStatus?.toJson(),
      'color': color,
    };
  }
}

class TaskStatusNameById {
  final int id;
  final String name;
  final String? createdAt;
  final String? updatedAt;

  TaskStatusNameById({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  // Метод для создания вложенного объекта из JSON
  factory TaskStatusNameById.fromJson(Map<String, dynamic> json) {
    return TaskStatusNameById(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
    );
  }

  // Метод для преобразования вложенного объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class DirectoryValues {
  final int id;
  final DirectoryEntry entry;

  DirectoryValues({
    required this.id,
    required this.entry,
  });

  factory DirectoryValues.fromJson(Map<String, dynamic> json) {
    return DirectoryValues(
      id: SafeConverters.toInt(json['id']),
      entry: DirectoryEntry.fromJson(SafeConverters.toMap(json['entry'])),
    );
  }
}

class DirectoryEntry {
  final int id;
  final DirectoryVV directory;
  final List<DirectoryValuePair> values; // Change to List
  final String createdAt;

  DirectoryEntry({
    required this.id,
    required this.directory,
    required this.values,
    required this.createdAt,
  });

  factory DirectoryEntry.fromJson(Map<String, dynamic> json) {
    return DirectoryEntry(
      id: SafeConverters.toInt(json['id']),
      directory: DirectoryVV.fromJson(SafeConverters.toMap(json['directory'])),
      values: SafeConverters.toList(json['values'])
          .map((v) => DirectoryValuePair.fromJson(SafeConverters.toMap(v)))
          .toList(),
      createdAt: SafeConverters.toSafeString(json['created_at']),
    );
  }
}

class DirectoryValuePair {
  final String key;
  final String value;

  DirectoryValuePair({
    required this.key,
    required this.value,
  });

  factory DirectoryValuePair.fromJson(Map<String, dynamic> json) {
    return DirectoryValuePair(
      key: SafeConverters.toSafeString(json['key']),
      value: SafeConverters.toSafeString(json['value']),
    );
  }
}

class DirectoryVV {
  final int id;
  final String name;
  final String? createdAt;

  DirectoryVV({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory DirectoryVV.fromJson(Map<String, dynamic> json) {
    return DirectoryVV(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
    );
  }
}

/*

*/
