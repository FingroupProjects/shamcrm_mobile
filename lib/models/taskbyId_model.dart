import 'package:crm_task_manager/models/project_model.dart';

class TaskById {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? createdAt;
  final String? description;
  final int statusId;
  final TaskStatusById? taskStatus;
  final String? color;
  final Project? project;
  final List<UserById>? user;
  final TaskFileById? file;
  final int priority;
  final ChatById? chat;
  final AuthorTask? author;
    final List<TaskCustomFieldsById> taskCustomFields;


  TaskById({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.createdAt,
    this.description,
    required this.statusId,
    this.taskStatus,
    this.color,
    this.project,
    this.user,
    this.file,
    required this.priority,
    this.chat, // Инициализация нового поля
    this.author, // Инициализация нового поля
    required this.taskCustomFields,
  });

  factory TaskById.fromJson(Map<String, dynamic> json, int taskStatusId) {
    // Преобразуем priority_level в int
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
      name: json['name'] is String ? json['name'] : 'Без имени',
      startDate: json['from'],
      endDate: json['to'],
      createdAt: json['created_at'] is String ? json['created_at'] : null,
      description: json['description'] is String ? json['description'] : '',
      statusId: taskStatusId,
      priority: priorityLevel,
      taskStatus: json['taskStatus'] != null &&
              json['taskStatus'] is Map<String, dynamic>
          ? TaskStatusById.fromJson(json['taskStatus'])
          : null,
      project:
          json['project'] != null && json['project'] is Map<String, dynamic>
              ? Project.fromJson(json['project'])
              : null,
      user: json['users'] != null && json['users'] is List
          ? (json['users'] as List)
              .map((userJson) => UserById.fromJson(userJson))
              .toList()
          : null,
      color: json['color'] is String ? json['color'] : null,
      file: json['file'] != null && json['file'] is Map<String, dynamic>
          ? TaskFileById.fromJson(json['file'])
          : null,
      chat: json['chat'] != null && json['chat'] is Map<String, dynamic>
          ? ChatById.fromJson(json['chat']) // Преобразуем JSON для чата
          : null,
      author: json['author'] != null && json['author'] is Map<String, dynamic>
          ? AuthorTask.fromJson(json['author'])
          : null,
      taskCustomFields: (json['task_custom_fields'] as List<dynamic>?)
              ?.map((field) => TaskCustomFieldsById.fromJson(field))
              .toList() ??
          [],
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

class TaskCustomFieldsById {
  final int id;
  final String key;
  final String value;

  TaskCustomFieldsById({
    required this.id,
    required this.key,
    required this.value,
  });

  factory TaskCustomFieldsById.fromJson(Map<String, dynamic> json) {
    return TaskCustomFieldsById(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      value: json['value'] ?? '',
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
  final String email;
  final String phone;

  UserById({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory UserById.fromJson(Map<String, dynamic> json) {
    return UserById(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Не указано',
      email: json['email'] ?? 'Не указано',
      phone: json['phone'] ?? 'Не указано',
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
  final TaskStatusNameById taskStatus;
  final String color;

  TaskStatusById({
    required this.id,
    required this.taskStatus,
    required this.color,
  });

  // Метод для создания объекта из JSON
  factory TaskStatusById.fromJson(Map<String, dynamic> json) {
    return TaskStatusById(
      id: json['id'],
      taskStatus: TaskStatusNameById.fromJson(json['taskStatus']),
      color: json['color'],
    );
  }

  // Метод для преобразования объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskStatus': taskStatus.toJson(),
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
