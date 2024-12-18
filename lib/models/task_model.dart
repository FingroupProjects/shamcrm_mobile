import 'package:crm_task_manager/models/project_model.dart';

class Task {
  final int id;
  final String name;
  final int? overdue; // Added here
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

  Task({
    required this.id,
    required this.name,
    this.overdue, // Added here
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
  });

  factory Task.fromJson(Map<String, dynamic> json, int taskStatusId) {
    print('JSON received: $json'); // Log the entire JSON object

    // Extract and validate overdue
    final overdueValue = json['overdue'];
    final int? parsedOverdue;
    if (overdueValue is int) {
      parsedOverdue = overdueValue;
    } else if (overdueValue is String) {
      parsedOverdue = int.tryParse(overdueValue);
    } else {
      parsedOverdue = null;
    }

    // Extract and validate priority_level
    final rawPriority = json['priority_level'];
    final int priorityLevel;
    if (rawPriority is int) {
      priorityLevel = rawPriority;
    } else if (rawPriority is String) {
      priorityLevel = int.tryParse(rawPriority) ?? 0;
    } else {
      priorityLevel = 0;
    }

    // Parse the users list
    final usersList = json['users'] != null && json['users'] is List
        ? (json['users'] as List)
            .map((userJson) => UserTaskImage.fromJson(userJson))
            .toList()
        : null;
    print('File field in JSON: ${json['file']}'); // Log the file field

    return Task(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name'] is String ? json['name'] : 'Без имени',
      overdue: parsedOverdue, // Added here
      startDate: json['from'],
      endDate: json['to'],
      description: json['description'] is String ? json['description'] : '',
      statusId: taskStatusId,
      priority: priorityLevel, // Use processed value
      taskStatus: json['taskStatus'] != null &&
              json['taskStatus'] is Map<String, dynamic>
          ? TaskStatus.fromJson(json['taskStatus'])
          : null,
      project:
          json['project'] != null && json['project'] is Map<String, dynamic>
              ? Project.fromJson(json['project'])
              : null,
      usersImage: usersList,
      user: json['users'] != null && json['users'] is Map<String, dynamic>
          ? UserTaskImage.fromJson(json['users'])
          : null,
      color: json['color'] is String ? json['color'] : null,
      file: json['file'] != null
          ? (json['file'] is Map<String, dynamic>
              ? TaskFile.fromJson(json['file'])
              : TaskFile(
                  name: json['file'].toString(),
                  size: 'Неизвестно',
                ))
          : null,
      taskCustomFields: (json['task_custom_fields'] as List<dynamic>?)
              ?.map((field) => TaskCustomField.fromJson(field))
              .toList() ??
          [],
    );
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
    return TaskCustomField(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
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
    return UserTaskImage(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Не указано',
      email: json['email'] ?? 'Не указано',
      phone: json['phone'] ?? 'Не указано',
      image: json['image'] ?? '', // Handle SVG data properly here.
    );
  }
}

// Add TaskFile model
// First, let's define the TaskFile model class
class TaskFile {
  final String name;
  final String size;

  TaskFile({required this.name, required this.size});

  Map<String, dynamic> toJson() => {
        "name": name,
        "size": size,
      };
  factory TaskFile.fromJson(Map<String, dynamic> json) {
    print(
        'TaskFileById JSON received: $json'); // Лог входящего JSON для TaskFileById

    if (json['name'] is String && json['size'] is String) {
      print('Parsed TaskFileById: name=${json['name']}, size=${json['size']}');

      return TaskFile(
        name: json["name"] as String,
        size: json["size"] as String,
      );
    }
    print('TaskFileById JSON format is invalid');

    throw Exception('Unexpected file format');
  }
}

class TaskStatus {
  final int id;
  final TaskStatusName taskStatus;
  final String color;

  TaskStatus({
    required this.id,
    required this.taskStatus,
    required this.color,
  });

  // Метод для создания объекта из JSON
  factory TaskStatus.fromJson(Map<String, dynamic> json) {
    print('TaskStatus JSON: $json'); // For debugging purposes
    return TaskStatus(
      id: json['id'],
      taskStatus: json['taskStatus'] is Map<String, dynamic>
          ? TaskStatusName.fromJson(json['taskStatus'])
          : TaskStatusName(
              id: 0, name: json['taskStatus'] ?? 'Неизвестный статус'),
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

  // Метод для создания вложенного объекта из JSON
  factory TaskStatusName.fromJson(Map<String, dynamic> json) {
    print('TaskStatusName JSON: $json'); // Добавим логирование
    return TaskStatusName(
      id: json['id'] ?? 0,
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
