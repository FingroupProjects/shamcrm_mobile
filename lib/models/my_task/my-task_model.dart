import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/task/project_model.dart';
import 'package:crm_task_manager/models/task/task_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

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
        id: SafeConverters.toInt(json['id']),
        name: SafeConverters.toSafeString(json['name'], defaultValue: 'Без имени'),
        taskNumber: SafeConverters.toIntOrNull(json['task_number']),
        startDate: SafeConverters.toStringOrNull(json['from']),
        endDate: SafeConverters.toStringOrNull(json['to']),
        description: SafeConverters.toSafeString(json['description']),
        statusId: taskStatusId,
        taskStatus: SafeConverters.toMapOrNull(json['taskStatus']) != null
            ? MyTaskStatus.fromJson(SafeConverters.toMap(json['taskStatus']))
            : null,
        file: SafeConverters.toMapOrNull(json['file']) != null
            ? MyTaskFile.fromJson(SafeConverters.toMap(json['file']))
            : null,
        taskCustomFields: SafeConverters.toList(json['task_custom_fields'])
            .map((field) => MyTaskCustomField.fromJson(SafeConverters.toMap(field)))
            .toList(),
        overdue: SafeConverters.toIntOrNull(json['overdue']),
        priority: SafeConverters.toIntOrNull(json['priority']),
        project: SafeConverters.toMapOrNull(json['project']) != null
            ? Project.fromJson(SafeConverters.toMap(json['project']))
            : null,
        usersImage: json['users_image'] != null
            ? SafeConverters.toList(json['users_image'])
                .map((u) => UserTaskImage.fromJson(SafeConverters.toMap(u)))
                .toList()
            : null,
        userName: SafeConverters.toStringOrNull(SafeConverters.toMapOrNull(json['user'])?['name']),
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
        id: SafeConverters.toInt(json['id']),
        key: SafeConverters.toSafeString(json['key']),
        value: SafeConverters.toSafeString(json['value']),
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
        name: SafeConverters.toSafeString(json["name"], defaultValue: 'Unknown'),
        size: SafeConverters.toSafeString(json["size"], defaultValue: 'Unknown'),
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
      id: SafeConverters.toInt(json['id']),
      title: SafeConverters.toSafeString(json['title'], defaultValue: 'Без статуса'),
      finalStep: SafeConverters.toBool(json['final_step']),
      color: SafeConverters.toSafeString(json['color'], defaultValue: '#FFFFFF'),
      organizationId: SafeConverters.toIntOrNull(json['organization_id']),
      position: SafeConverters.toInt(json['position']),
      authorId: SafeConverters.toIntOrNull(json['author_id']),
      tasksCount: SafeConverters.toInt(json['tasks_count']),
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
