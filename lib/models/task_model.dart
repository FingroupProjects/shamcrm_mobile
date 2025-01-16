// Вспомогательные функции для безопасного парсинга
import 'package:crm_task_manager/models/project_model.dart';

String? parseString(dynamic value) {
  if (value is String) return value;
  if (value is Map<String, dynamic>) {
    return value.toString(); // If it's a Map, convert it to a string
  }
  return null;
}

int? parseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class Task {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? description;
  final int statusId;
  final TaskStatus? taskStatus;
  final String? color;
  final Project? project;
  final UserTaskImage? user;
  final List<UserTaskImage>? usersImage;
  final TaskFile? file;
  final int priority;
  final List<TaskCustomField> taskCustomFields;
  final int? overdue;

  Task({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.description,
    required this.statusId,
    this.taskStatus,
    this.color,
    this.project,
    this.usersImage,
    this.user,
    this.file,
    required this.priority,
    required this.taskCustomFields,
    this.overdue,
  });

  factory Task.fromJson(Map<String, dynamic> json, int taskStatusId) {
    try {
      return Task(
        id: json['id'] is int ? json['id'] : 0,
        name: parseString(json['name']) ?? 'Без имени',
        startDate: parseString(json['from']),
        endDate: parseString(json['to']),
        description: parseString(json['description']) ?? '',
        statusId: taskStatusId,
        priority: parseInt(json['priority_level']) ?? 1,
        overdue: parseInt(json['overdue']) ?? 0,
        taskStatus: json['taskStatus'] != null
            ? TaskStatus.fromJson(json['taskStatus'])
            : null,
        project: json['project'] != null ? Project.fromJson(json['project']) : null,
        usersImage: (json['users'] as List?)
            ?.map((userJson) => UserTaskImage.fromJson(userJson))
            .toList(),
        user: json['users'] != null && json['users'] is Map<String, dynamic>
            ? UserTaskImage.fromJson(json['users'])
            : null,
        color: parseString(json['color']),
        file: json['file'] != null
            ? (json['file'] is Map<String, dynamic>
                ? TaskFile.fromJson(json['file'])
                : TaskFile(name: json['file'].toString(), size: 'Неизвестно'))
            : null,
        taskCustomFields: (json['task_custom_fields'] as List?)
                ?.map((field) => TaskCustomField.fromJson(field))
                .toList() ??
            [],
      );
    } catch (e) {
      print('Error parsing Task: $e');
      return Task(
        id: 0,
        name: 'Ошибка загрузки',
        startDate: null,
        endDate: null,
        description: 'Ошибка при получении данных',
        statusId: taskStatusId,
        priority: 1,
        taskCustomFields: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'from': startDate,
      'to': endDate,
      'description': description,
      'statusId': statusId,
      'taskStatus': taskStatus?.toJson(),
      'color': color,
      'project': project?.toJson(),
      'user': user?.toJson(),
      'users': usersImage?.map((e) => e.toJson()).toList(),
      'file': file?.toJson(),
      'priority_level': priority,
      'task_custom_fields': taskCustomFields.map((e) => e.toJson()).toList(),
      'overdue': overdue,
    };
  }
}

class TaskCustomField {
  final int id;
  final String key;
  final String value;

  TaskCustomField({
    required this.id,
    required this.key,
    required this.value,
  });

  factory TaskCustomField.fromJson(Map<String, dynamic> json) {
    try {
      return TaskCustomField(
        id: json['id'] ?? 0,
        key: json['key'] ?? '',
        value: json['value'] ?? '',
      );
    } catch (e) {
      print('Error parsing TaskCustomField: $e');
      return TaskCustomField(id: 0, key: 'Unknown', value: 'Unknown');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
    };
  }
}

class UserTaskImage {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String image;

  UserTaskImage({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.image,
  });

  factory UserTaskImage.fromJson(Map<String, dynamic> json) {
    try {
      return UserTaskImage(
        id: json['id'] ?? 0,
        name: parseString(json['name']) ?? 'Не указано',
        email: parseString(json['email']) ?? 'Не указано',
        phone: parseString(json['phone']) ?? 'Не указано',
        image: parseString(json['image']) ?? '',
      );
    } catch (e) {
      print('Error parsing UserTaskImage: $e');
      return UserTaskImage(
        id: 0,
        name: 'Не указано',
        email: 'Не указано',
        phone: 'Не указано',
        image: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'image': image,
    };
  }
}

class TaskFile {
  final String name;
  final String size;

  TaskFile({required this.name, required this.size});

  Map<String, dynamic> toJson() => {
        "name": name,
        "size": size,
      };

  factory TaskFile.fromJson(Map<String, dynamic> json) {
    try {
      return TaskFile(
        name: json["name"] ?? 'Unknown',
        size: json["size"] ?? 'Unknown',
      );
    } catch (e) {
      print('Error parsing TaskFile: $e');
      return TaskFile(name: 'Unknown', size: 'Unknown');
    }
  }
}

class TaskStatus {
  final int id;
  final TaskStatusName taskStatus;
  final String color;
  final int tasksCount;

  TaskStatus({
    required this.id,
    required this.taskStatus,
    required this.color,
    required this.tasksCount,
  });

  factory TaskStatus.fromJson(Map<String, dynamic> json) {
    try {
      return TaskStatus(
        id: json['id'],
        taskStatus: json['taskStatus'] is Map<String, dynamic>
            ? TaskStatusName.fromJson(json['taskStatus'])
            : TaskStatusName(
                id: 0, name: parseString(json['taskStatus']) ?? 'Неизвестный статус'),
        color: parseString(json['color']) ?? 'Неизвестный цвет',
        tasksCount: parseInt(json['tasks_amount']) ?? 0,
      );
    } catch (e) {
      print('Error parsing TaskStatus: $e');
      return TaskStatus(id: 0, taskStatus: TaskStatusName(id: 0, name: 'Ошибка'), color: 'Unknown', tasksCount: 0);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskStatus': taskStatus.toJson(),
      'color': color,
      'tasks_amount': tasksCount,
    };
  }
}

class TaskStatusName {
  final int id;
  final String name;
  final String? createdAt;
  final String? updatedAt;

  TaskStatusName({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskStatusName.fromJson(Map<String, dynamic> json) {
    try {
      return TaskStatusName(
        id: json['id'] ?? 0,
        name: parseString(json['name']) ?? 'Неизвестное имя',
        createdAt: parseString(json['created_at']),
        updatedAt: parseString(json['updated_at']),
      );
    } catch (e) {
      print('Error parsing TaskStatusName: $e');
      return TaskStatusName(id: 0, name: 'Неизвестное имя');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
