import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/project_model.dart';
import 'package:crm_task_manager/models/task_model.dart';

class MyTask {
  final int id;
  final String name;
  final int? taskNumber;
  final String? startDate;
  final String? endDate;
  final String? description;
  final int statusId;
  final MyTaskStatus? taskStatus;
  final MyTaskFile? file;
  final List<MyTaskCustomField> taskCustomFields;
  final int? overdue;
  // Дополнительные поля как в Task (nullable — приходят если есть)
  final int? priority;
  final Project? project;
  final List<UserTaskImage>? usersImage;
  final String? userName;

  MyTask({
    required this.id,
    required this.name,
    this.taskNumber,
    this.startDate,
    this.endDate,
    this.description,
    required this.statusId,
    this.taskStatus,
    this.file,
    required this.taskCustomFields,
    this.overdue,
    this.priority,
    this.project,
    this.usersImage,
    this.userName,
  });

  factory MyTask.fromJson(Map<String, dynamic> json, int taskStatusId) {
    try {
      return MyTask(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Без имени',
        taskNumber: json['task_number'] is int ? json['task_number'] : 0,
        startDate: json['from'],
        endDate: json['to'],
        description: json['description'] ?? '',
        statusId: taskStatusId,
        taskStatus: json['taskStatus'] != null
            ? MyTaskStatus.fromJson(json['taskStatus'])
            : null,
        file: json['file'] != null && json['file'] is Map<String, dynamic>
            ? MyTaskFile.fromJson(json['file'])
            : null,
        taskCustomFields: json['task_custom_fields'] != null
            ? (json['task_custom_fields'] as List)
                .map((field) => MyTaskCustomField.fromJson(field))
                .toList()
            : [],
        overdue: json['overdue'] is int ? json['overdue'] : 0,
        priority: json['priority'] is int ? json['priority'] : null,
        project: json['project'] != null
            ? Project.fromJson(json['project'])
            : null,
        usersImage: json['users_image'] != null
            ? (json['users_image'] as List)
                .map((u) => UserTaskImage.fromJson(u))
                .toList()
            : null,
        userName: json['user']?['name'],
      );
    } catch (e) {
      debugPrint('Error parsing MyTask: $e, JSON: $json');
      return MyTask(
        id: 0,
        name: 'Ошибка загрузки',
        startDate: null,
        endDate: null,
        description: 'Ошибка при получении данных',
        statusId: taskStatusId,
        taskCustomFields: [],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'task_number': taskNumber,
      'from': startDate,
      'to': endDate,
      'description': description,
      'statusId': statusId,
      'taskStatus': taskStatus?.toJson(),
      'file': file?.toJson(),
      'task_custom_fields': taskCustomFields.map((e) => e.toJson()).toList(),
      'overdue': overdue,
      'priority': priority,
      'project': project?.toJson(),
      'users_image': usersImage?.map((u) => u.toJson())?.toList(),
    };
  }
}

class MyTaskCustomField {
  final int id;
  final String key;
  final String value;

  MyTaskCustomField({
    required this.id,
    required this.key,
    required this.value,
  });

  factory MyTaskCustomField.fromJson(Map<String, dynamic> json) {
    try {
      return MyTaskCustomField(
        id: json['id'] ?? 0,
        key: json['key'] ?? '',
        value: json['value'] ?? '',
      );
    } catch (e) {
      debugPrint('Error parsing MyTaskCustomField: $e');
      return MyTaskCustomField(id: 0, key: 'Unknown', value: 'Unknown');
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

class MyTaskFile {
  final String name;
  final String size;

  MyTaskFile({required this.name, required this.size});

  Map<String, dynamic> toJson() => {
        "name": name,
        "size": size,
      };

  factory MyTaskFile.fromJson(Map<String, dynamic> json) {
    try {
      return MyTaskFile(
        name: json["name"] ?? 'Unknown',
        size: json["size"] ?? 'Unknown',
      );
    } catch (e) {
      return MyTaskFile(name: 'Unknown', size: 'Unknown');
    }
  }
}

class MyTaskStatus {
  final int id;
  final String title;
  final String? color;
  final int? organizationId;
  final int position;
  final int tasksCount;
  final int? authorId;
  final bool finalStep;

  MyTaskStatus({
    required this.id,
    required this.title,
    this.color,
    this.organizationId,
    required this.position,
    required this.tasksCount,
    this.authorId,
    required this.finalStep,
  });

  factory MyTaskStatus.fromJson(Map<String, dynamic> json) {
    return MyTaskStatus(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Без статуса',
      finalStep: json['final_step'] == true || json['final_step'] == 1,
      color: json['color'] ?? '#FFFFFF',
      organizationId: json['organization_id'] as int?,
      position: json['position'] ?? 0,
      authorId: json['author_id'] ?? 0,
      tasksCount: json['tasks_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color,
      'organization_id': organizationId,
      'position': position,
      'author_id': authorId,
      'tasks_count': tasksCount,
    };
  }
}
