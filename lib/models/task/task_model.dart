import 'package:crm_task_manager/models/deal/dealById_model.dart';
import 'package:crm_task_manager/models/deal/deal_model.dart';
import 'package:crm_task_manager/models/task/project_model.dart';
import 'package:crm_task_manager/models/user/user_data_response.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

class Task {
  final int id;
  final int? taskNumber;
  final String name;
  final String? startDate;
  final String? endDate;
  final String? description;
  final int statusId;
  final TaskStatus? taskStatus;
  final String? color;
  final Project? project;
  final Deal? deal;
  final UserData? user;
  final List<UserTaskImage>? usersImage;
  final TaskFile? file;
  final int priority;
  // final List<TaskCustomField> taskCustomFields;
  final int? overdue;
  final List<CustomFields> customFields;

  Task({
    required this.id,
    this.taskNumber,
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
    // required this.taskCustomFields,
    required this.customFields,
    this.overdue,
    this.deal,
  });

  factory Task.fromJson(Map<String, dynamic> json, int taskStatusId) {
    final priorityLevel = SafeConverters.toInt(json['priority_level']);
    try {
      return Task(
        id: SafeConverters.toInt(json['id']),
        taskNumber: SafeConverters.toIntOrNull(json['task_number']),
        name: SafeConverters.toSafeString(json['name'], defaultValue: 'Без имени'),
        startDate: SafeConverters.toStringOrNull(json['from']),
        endDate: SafeConverters.toStringOrNull(json['to']),
        description: SafeConverters.toSafeString(json['description']),
        statusId: taskStatusId,
        priority: priorityLevel,
        overdue: SafeConverters.toIntOrNull(json['overdue']),
        taskStatus: SafeConverters.toMapOrNull(json['taskStatus']) != null
            ? TaskStatus.fromJson(SafeConverters.toMap(json['taskStatus']))
            : null,
        project: SafeConverters.toMapOrNull(json['project']) != null
            ? Project.fromJson(SafeConverters.toMap(json['project']))
            : null,
        usersImage: json['users'] == null
            ? null
            : SafeConverters.toList(json['users'])
                .map((userJson) =>
                    UserTaskImage.fromJson(SafeConverters.toMap(userJson)))
                .toList(),
        user: SafeConverters.toMapOrNull(json['user']) != null
            ? UserData.fromJson(SafeConverters.toMap(json['user']))
            : null,
        deal: SafeConverters.toMapOrNull(json['deal']) != null
            ? Deal.fromJson(SafeConverters.toMap(json['deal']), 0)
            : null,
        color: SafeConverters.toStringOrNull(json['color']),
        file: json['file'] != null
            ? (SafeConverters.toMapOrNull(json['file']) != null
                ? TaskFile.fromJson(SafeConverters.toMap(json['file']))
                : TaskFile(
                    name: SafeConverters.toSafeString(json['file']),
                    size: 'Неизвестно'))
            : null,
        customFields: SafeConverters.toList(json['custom_fields'])
            .map((field) => CustomFields.fromJson(SafeConverters.toMap(field)))
            .toList(),
      );
    } catch (e) {
      //print('Error parsing Task: $e');
      return Task(
        id: 0,
        taskNumber: 0,
        name: 'Ошибка загрузки',
        startDate: null,
        endDate: null,
        description: 'Ошибка при получении данных',
        statusId: taskStatusId,
        priority: 1,
        customFields: [],
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
      'custom_fields': customFields.map((e) => e.toJson()).toList(),
      'overdue': overdue,
    };
  }
}

class CustomFields {
  final String name;
  final String value;
  final int fieldId;
  final String? type;

  CustomFields({
    required this.name,
    required this.value,
    required this.fieldId,
    this.type,
  });

  factory CustomFields.fromJson(Map<String, dynamic> json) {
    return CustomFields(
      name: SafeConverters.toSafeString(json['name']),
      value: SafeConverters.toSafeString(json['value']),
      fieldId: SafeConverters.toInt(json['field_id']),
      type: SafeConverters.toStringOrNull(json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'field_id': fieldId,
      'type': type,
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
        id: SafeConverters.toInt(json['id']),
        name: SafeConverters.toSafeString(json['name'], defaultValue: 'Не указано'),
        email: SafeConverters.toSafeString(json['email'], defaultValue: 'Не указано'),
        phone: SafeConverters.toSafeString(json['phone'], defaultValue: 'Не указано'),
        image: SafeConverters.toSafeString(json['image']),
      );
    } catch (e) {
      //print('Error parsing UserTaskImage: $e');
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
        name: SafeConverters.toSafeString(json['name'], defaultValue: 'Unknown'),
        size: SafeConverters.toSafeString(json['size'], defaultValue: 'Unknown'),
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
  final bool isUnassembled;
  final List<String> roles; // Added roles field

  TaskStatus({
    required this.id,
    this.taskStatus,
    required this.color,
    required this.tasksCount,
    required this.needsPermission,
    required this.finalStep,
    required this.checkingStep,
    required this.isUnassembled,
    required this.roles, // Initialize roles
  });

  factory TaskStatus.fromJson(Map<String, dynamic> json) {
    return TaskStatus(
      id: SafeConverters.toInt(json['id']),
      needsPermission: SafeConverters.toBool(json['needs_permission']),
      finalStep: SafeConverters.toBool(json['final_step']),
      checkingStep: SafeConverters.toBool(json['checking_step']),
      isUnassembled: SafeConverters.toBool(json['is_unassembled']),
      taskStatus: SafeConverters.toMapOrNull(json['taskStatus']) != null
          ? TaskStatusName.fromJson(SafeConverters.toMap(json['taskStatus']))
          : null,
      color: SafeConverters.toSafeString(json['color'], defaultValue: 'Неизвестный цвет'),
      tasksCount: SafeConverters.toSafeString(json['tasks_amount'], defaultValue: '0'),
      roles: SafeConverters.toList(json['roles'])
          .map((role) => SafeConverters.toSafeString(role))
          .toList(),
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
      'is_unassembled': isUnassembled,
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name'], defaultValue: 'Неизвестное имя'),
      createdAt: SafeConverters.toStringOrNull(json['created_at']),
      updatedAt: SafeConverters.toStringOrNull(json['updated_at']),
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
