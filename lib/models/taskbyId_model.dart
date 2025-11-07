import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/project_model.dart';

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
  final List<TaskCustomFieldsById> taskCustomFields;
  final String? taskFile;
  final int isFinished;
  final List<TaskFiles>? files;
  final List<DirectoryValues>? directoryValues; // Новое поле

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
    required this.taskCustomFields,
    this.taskFile,
    this.files,
    required this.isFinished,
    this.directoryValues, // Инициализация нового поля
  });

  factory TaskById.fromJson(Map<String, dynamic> json, int taskStatusId) {
    final rawPriority = json['priority_level'];
    final int priorityLevel;
    if (rawPriority is int) {
      priorityLevel = rawPriority;
    } else if (rawPriority is String) {
      priorityLevel = int.tryParse(rawPriority) ?? 0;
    } else {
      priorityLevel = 0;
    }

    return TaskById(
      id: json['id'] is int ? json['id'] : 0,
      taskNumber: json['task_number'] is int ? json['task_number'] : 0,
      name: json['name'] is String ? json['name'] : 'Без имени',
      startDate: json['from'],
      endDate: json['to'],
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      description: json['description'] is String ? json['description'] : '',
      statusId: taskStatusId,
      priority: priorityLevel,
      taskStatus: json['taskStatus'] != null && json['taskStatus'] is Map<String, dynamic>
          ? TaskStatusById.fromJson(json['taskStatus'])
          : null,
      project: json['project'] != null && json['project'] is Map<String, dynamic>
          ? Project.fromJson(json['project'])
          : null,
      user: json['users'] != null && json['users'] is List
          ? (json['users'] as List)
              .map((userJson) => UserById.fromJson(userJson))
              .toList()
          : null,
      deal: json['deal'] != null && json['deal'] is Map<String, dynamic>
          ? DealById.fromJson(json['deal'], 0)
          : null,
      color: json['color'] is String ? json['color'] : null,
      taskFile: json['file'],
      files: json['files'] != null && json['files'] is List
          ? (json['files'] as List)
              .map((fileJson) => TaskFiles.fromJson(fileJson))
              .toList()
          : null,
      chat: json['chat'] != null && json['chat'] is Map<String, dynamic>
          ? ChatById.fromJson(json['chat'])
          : null,
      author: json['author'] != null && json['author'] is Map<String, dynamic>
          ? AuthorTask.fromJson(json['author'])
          : null,
      taskCustomFields: (json['task_custom_fields'] as List<dynamic>?)
              ?.map((field) => TaskCustomFieldsById.fromJson(field))
              .toList() ??
          [],
      isFinished: json['is_finished'] is int ? json['is_finished'] : 0,
      directoryValues: json['directory_values'] != null && json['directory_values'] is List
          ? (json['directory_values'] as List)
              .map((dirJson) => DirectoryValues.fromJson(dirJson))
              .toList()
          : null, // Парсинг directory_values
    );
  }
}

class AuthorTask {
  final int id;
  final String name;

  AuthorTask({
    required this.id,
    required this.name,
  });

  factory AuthorTask.fromJson(Map<String, dynamic> json) {
    return AuthorTask(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Не указан',
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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      path: json['path'] ?? '',
    );
  }
}

class TaskCustomFieldsById {
  final int id;
  final String key;
  final String value;
  final String type;

  TaskCustomFieldsById({
    required this.id,
    required this.key,
    required this.value,
    required this.type,
  });

  factory TaskCustomFieldsById.fromJson(Map<String, dynamic> json) {
    return TaskCustomFieldsById(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      value: json['value'] ?? '', type: '',
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
      id: json['id'] ?? 0,
      lead: json['lead'] as String?,
      type: json['type'] as String? ?? 'unknown',
      user: json['user'] as String?,
      canSendMessage: json["can_send_message"] ?? false,
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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
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
        name: json["name"] as String,
        size: json["size"] as String,
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
      id: json['id'] ?? 0,
      taskStatus: json['taskStatus'] != null && json['taskStatus'] is Map<String, dynamic>
          ? TaskStatusNameById.fromJson(json['taskStatus'])
          : null, // Handle null case
      color: json['color'] ?? '',
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
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
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
      id: json['id'] ?? 0,
      entry: DirectoryEntry.fromJson(json['entry']),
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
    final valuesJson = json['values'];
    final valuesList = valuesJson is List
        ? valuesJson
        .map((v) => DirectoryValuePair.fromJson(v))
        .toList()
        : <DirectoryValuePair>[];

    return DirectoryEntry(
      id: json['id'] ?? 0,
      directory: DirectoryVV.fromJson(json['directory']),
      values: valuesList,
      createdAt: json['created_at'] ?? '',
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
      key: json['key'] ?? '',
      value: json['value'] ?? '',
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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['created_at'],
    );
  }
}

/*

*/