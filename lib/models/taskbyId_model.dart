import 'package:crm_task_manager/models/history_model_task.dart';
import 'package:crm_task_manager/models/project_model.dart';

class TaskById {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? description;
  final int statusId;
  final TaskStatusById? taskStatus;
  final String? color;
  final Project? project;
  final User? user;
  final TaskFileById? file;
  final int priority;

  TaskById({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.description,
    required this.statusId,
    this.taskStatus,
    this.color,
    this.project,
    this.user,
    this.file,
    required this.priority,
  });

  factory TaskById.fromJson(Map<String, dynamic> json, int taskStatusId) {
    // Извлекаем и проверяем priority_level
    final rawPriority = json['priority_level'];
    print('Raw priority from JSON: $rawPriority'); // Debug print
    
    // Преобразуем priority_level в int
    final int priorityLevel;
    if (rawPriority is int) {
      priorityLevel = rawPriority;
    } else if (rawPriority is String) {
      priorityLevel = int.tryParse(rawPriority) ?? 0;
    } else {
      priorityLevel = 0;
    }
    
    print('Converted priority level: $priorityLevel'); // Debug print

    return TaskById(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name'] is String ? json['name'] : 'Без имени',
      startDate: json['from'],
      endDate: json['to'],
      description: json['description'] is String ? json['description'] : '',
      statusId: taskStatusId,
      priority: priorityLevel, // Используем обработанное значение
      taskStatus: json['taskStatus'] != null && json['taskStatus'] is Map<String, dynamic>
      ? TaskStatusById.fromJson(json['taskStatus'])
      : null,
      project: json['project'] != null && json['project'] is Map<String, dynamic>
          ? Project.fromJson(json['project'])
          : null,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'])
          : null,
      color: json['color'] is String ? json['color'] : null,
      file: json['file'] != null && json['file'] is Map<String, dynamic>
          ? TaskFileById.fromJson(json['file'])
          : null,
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


      // taskStatus: json['taskStatus'] != null ? TaskStatusById.fromJson(json['taskStatus']) : TaskStatusById(id: 0, taskStatus: TaskStatusNameById(id: 0, name: 'Не указан'), color: '#000000'),
