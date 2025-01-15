import 'package:crm_task_manager/models/task_model.dart';

abstract class TaskEvent {}

class FetchTaskStatuses extends TaskEvent {}

class FetchTasks extends TaskEvent {
  final int statusId;
  final String? query; // Добавьте параметр для поиска
  final int? userId; // Добавляем поле managerId

  FetchTasks(
    this.statusId, {
    this.query,
    this.userId, // Добавляем в конструктор
  });
}

class FetchMoreTasks extends TaskEvent {
  final int statusId;
  final int currentPage;

  FetchMoreTasks(this.statusId, this.currentPage);
}

class CreateTask extends TaskEvent {
  final String name;
  final int statusId;
  final int? taskStatusId;
  final int? priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? projectId;
  final List<int>?
      userId; // Новый параметр для списка идентификаторов пользователей
  final String? description;
  final String? filePath;
  final List<Map<String, String>>? customFields;

  CreateTask({
    required this.name,
    required this.statusId,
    required this.taskStatusId,
    this.priority,
    this.startDate,
    this.endDate,
    this.projectId,
    this.userId, // Передаём новый параметр в конструктор
    this.description,
    this.customFields,
    this.filePath,
  });
}

class UpdateTask extends TaskEvent {
  final int taskId;
  final String name;
  final int statusId;
  final String? priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? projectId;
  final List<int>?
      userId; // Новый параметр для списка идентификаторов пользователей
  final String? description;
  final int taskStatusId;
  final List<Map<String, String>>? customFields;

  final String? filePath;

  UpdateTask({
    required this.taskId,
    required this.name,
    required this.statusId,
    this.priority,
    this.startDate,
    this.endDate,
    this.projectId,
    this.userId,
    this.description,
    required this.taskStatusId,
    this.customFields,
    this.filePath,
  });
}

class CreateTaskStatus extends TaskEvent {
  final int taskStatusNameId;
  final int projectId;
  final int organizationId;
  final bool needsPermission;
  final List<int>? roleIds;

  CreateTaskStatus({
    required this.taskStatusNameId,
    required this.projectId,
    required this.organizationId,
    required this.needsPermission,
    this.roleIds,
  });
}

class DeleteTask extends TaskEvent {
  final int taskId;

  DeleteTask(this.taskId);
}

class DeleteTaskStatuses extends TaskEvent {
  final int taskStatusId;

  DeleteTaskStatuses(this.taskStatusId);
}
