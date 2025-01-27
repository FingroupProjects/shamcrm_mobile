import 'package:crm_task_manager/models/project_model.dart';
import 'package:crm_task_manager/models/role_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';

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
  final UserData? user;
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
    final rawPriority = json['priority_level'];
    final int priorityLevel;
    if (rawPriority is int) {
      priorityLevel = rawPriority;
    } else if (rawPriority is String) {
      priorityLevel = int.tryParse(rawPriority) ?? 0;
    } else {
      priorityLevel = 0;
    }
    try {
      return Task(
        id: json['id'] is int ? json['id'] : 0,
        name: json['name'] is String ? json['name'] : 'Без имени',
        startDate: json['from'] is String ? json['from'] : null,
        endDate: json['to'] is String ? json['to'] : null,
        description: json['description'] is String ? json['description'] : '',
        statusId: taskStatusId,
        priority: priorityLevel,
        overdue: json['overdue'] is int ? json['overdue'] : 0,
        taskStatus: json['taskStatus'] != null &&
                json['taskStatus'] is Map<String, dynamic>
            ? TaskStatus.fromJson(json['taskStatus'])
            : null,
        project:
            json['project'] != null ? Project.fromJson(json['project']) : null,
        usersImage: (json['users'] as List?)
            ?.map((userJson) => UserTaskImage.fromJson(userJson))
            .toList(),
        user: json['user'] != null && json['user'] is Map<String, dynamic>
            ? UserData.fromJson(json['user'])
            : null,
        color: json['color'] is String ? json['color'] : null,
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
        name: json['name'] is String ? json['name'] : 'Не указано',
        email: json['email'] is String ? json['email'] : 'Не указано',
        phone: json['phone'] is String ? json['phone'] : 'Не указано',
        image: json['image'] is String ? json['image'] : '',
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
      return TaskFile(name: 'Unknown', size: 'Unknown');
    }
  }
}
class TaskStatus {
  final int id;
  final TaskStatusName? taskStatus;
  final String color;
  final String tasksCount; // Changed to String
  final bool needsPermission;
  final bool finalStep;
  final bool checkingStep;
  final List<String> roles; // Added roles field

  TaskStatus({
    required this.id,
    this.taskStatus,
    required this.color,
    required this.tasksCount,
    required this.needsPermission,
    required this.finalStep,
    required this.checkingStep,
    required this.roles, // Initialize roles
  });

  factory TaskStatus.fromJson(Map<String, dynamic> json) {
    return TaskStatus(
      id: json['id'] as int,
      needsPermission:
          json['needs_permission'] == true || json['needs_permission'] == 1,
      finalStep: json['final_step'] == true || json['final_step'] == 1,
      checkingStep: json['checking_step'] == true || json['checking_step'] == 1,
      taskStatus: json['taskStatus'] != null &&
              json['taskStatus'] is Map<String, dynamic>
          ? TaskStatusName.fromJson(json['taskStatus'])
          : null,
      color: json['color'] is String ? json['color'] : 'Неизвестный цвет',
      tasksCount: json['tasks_amount']?.toString() ?? '0',
      roles: (json['roles'] as List<dynamic>?)
              ?.map((role) => role.toString())
              .toList() ??
          [], // Parse roles as a list of strings
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskStatus': taskStatus?.toJson(),
      'color': color,
      'tasks_amount': tasksCount,
      'needs_permission': needsPermission,
      'final_step': finalStep,
      'checking_step': checkingStep,
      'roles': roles, // Include roles in toJson
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
    return TaskStatusName(
      id: json['id'] as int? ?? 0,
      name: json['name'] is String ? json['name'] : 'Неизвестное имя',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
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
