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

  Task({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.description,
    required this.statusId, // Required statusId
    this.taskStatus,
    // this.project,
    this.color,
    this.project,
    this.user,
  });

  factory Task.fromJson(Map<String, dynamic> json, int taskStatusId) { // Added taskStatusId parameter
    return Task(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name'] is String ? json['name'] : 'Без имени',
      startDate: json['start_date'] is String ? json['start_date'] : null,
      endDate: json['end_date'] is String ? json['end_date'] : null,
      description: json['description'] is String ? json['description'] : '',
      statusId: taskStatusId,
      taskStatus: json['taskStatus'] != null && json['taskStatus'] is Map<String, dynamic>
          ? TaskStatus.fromJson(json['taskStatus'])
          : null,
      project: json['project'] != null && json['project'] is Map<String, dynamic>
          ? Project.fromJson(json['project'])
          : null,
      user: json['user'] != null && json['user'] is Map<int, dynamic>
          ? User.fromJson(json['user'])
          : null,
      color: json['color'] is String ? json['color'] : null,
    );
  }

  String? get priority => null;
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

// class Project {
//   final int id;
//   final String name;
//   // final String? startDate;
//   // final String? endDate;

//   Project({
//     required this.id,
//     required this.name,
//     // this.startDate,
//     // this.endDate,
//   });

//   factory Project.fromJson(Map<String, dynamic> json) {
//     return Project(
//       id: json['id'] is int ? json['id'] : 0,
//       name: json['name'] is String ? json['name'] : 'Без имени',
//       // startDate: json['start_date'] is String ? json['start_date'] : null,
//       // endDate: json['end_date'] is String ? json['end_date'] : null,
//     );
//   }
  
// }class User {
//   final int id;
//   final String name;
//   final String? startDate;
//   final String? endDate;

//   User({
//     required this.id,
//     required this.name,
//     this.startDate,
//     this.endDate,
//   });

//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       id: json['id'] is int ? json['id'] : 0,
//       name: json['name'] is String ? json['name'] : 'Без имени',
//       startDate: json['start_date'] is String ? json['start_date'] : null,
//       endDate: json['end_date'] is String ? json['end_date'] : null,
//     );
//   }}
