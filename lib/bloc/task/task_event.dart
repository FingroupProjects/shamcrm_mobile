
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

abstract class TaskEvent {}

class FetchTaskStatuses extends TaskEvent {}

class FetchTasks extends TaskEvent {
  final int statusId;
  final String? query; // Добавьте параметр для поиска
  final List<int>? userIds; // Изменено: массив менеджеров

  FetchTasks(
    this.statusId, {
    this.query,
    this.userIds, // Добавляем в конструктор
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
  final List<int>?userId; // Новый параметр для списка идентификаторов пользователей
  final String? description;
  final String? filePath;
  final List<Map<String, String>>? customFields;
  final AppLocalizations localizations;  // Add this to your event

 
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
    required this.localizations,  // Add this to constructor

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
  final List<int>? userId; // Новый параметр для списка идентификаторов пользователей
  final String? description;
  final int taskStatusId;
  final List<Map<String, String>>? customFields;
  final String? filePath;
  final AppLocalizations localizations;  // Add this to your event


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
    required this.localizations,  // Add this to constructor

  });
}

class CreateTaskStatus extends TaskEvent {
  final int taskStatusNameId;
  final int projectId;
  final int organizationId;
  final bool needsPermission;
  final List<int>? roleIds;
  final AppLocalizations localizations;  // Add this to your event


  CreateTaskStatus({
    required this.taskStatusNameId,
    required this.projectId,
    required this.organizationId,
    required this.needsPermission,
    this.roleIds,
    required this.localizations,  // Add this to constructor

  });
}

class DeleteTask extends TaskEvent {
  final int taskId;
    final AppLocalizations localizations;  // Add this to your event


  DeleteTask(
    this.taskId,
      this.localizations,  // Add this to constructor

    );
}

class DeleteTaskStatuses extends TaskEvent {
  final int taskStatusId;
  final AppLocalizations localizations;  // Add this to your event


  DeleteTaskStatuses(
    this.taskStatusId,    
     this.localizations,  // Add this to constructor
);
}
