import 'dart:io';

import 'package:crm_task_manager/models/history_model_task.dart';
import 'package:crm_task_manager/models/project_model.dart';

class Task {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? description;
  final int statusId; // Added back statusId
  final TaskStatus? taskStatus;
  // final Project? project;
  final String? color;
  final Project? project;
  final User? user;
  final TaskFile? file;
  final int? priority;

  Task({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.description,
    required this.statusId, // Required statusId
    this.taskStatus,
    // this.project,
    this.color,
    this.project,
    this.user,
    this.file,
    this.priority,
  });

  factory Task.fromJson(Map<String,
   dynamic> json, int taskStatusId) {
    // Added taskStatusId parameter
    return Task(
      id: json['id'] is int ? json['id'] : 0,
       priority: json['priority_level'] is int ? json['priority_level']:0,
      name: json['name'] is String ? json['name'] : 'Без имени',
      startDate: json['from'] ,
      endDate: json['to'] ,
      description: json['description'] is String ? json['description'] : '',

      statusId: taskStatusId,
      taskStatus: json['taskStatus'] != null &&
              json['taskStatus'] is Map<String, dynamic>
          ? TaskStatus.fromJson(json['taskStatus'])
          : null,
      project:
          json['project'] != null && json['project'] is Map<String, dynamic>
              ? Project.fromJson(json['project'])
              : null,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'])
          : null,
      color: json['color'] is String ? json['color'] : null,
      // file: json['file'] != null ? TaskFile.fromJson(json['file']) : '', // Parse file data
      // file: json['file'] != null && json['file'] is Map<String, dynamic>
      //     ? TaskFile.fromJson(json['user'])
      //     : null,
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

  factory TaskFile.fromJson(Map<String, dynamic> json) => TaskFile(
    name: json["name"] as String,
    size: json["size"] as String,
  );
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
    return TaskStatus(
      id: json['id'],
      taskStatus: TaskStatusName.fromJson(json['taskStatus']),
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
    return TaskStatusName(
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