
import 'package:crm_task_manager/models/taskbyId_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

abstract class TaskEvent {}

class FetchTaskStatuses extends TaskEvent {}

class FetchTasks extends TaskEvent {
  final int statusId;
  final String? query; 
  final List<int>? userIds; 
  final int? statusIds; 
  final DateTime? fromDate; 
  final DateTime? toDate; 

  FetchTasks(
    this.statusId, {
    this.query,
    this.userIds,
    this.statusIds,
    this.fromDate,
    this.toDate,
  });
}
class FetchTaskStatus extends TaskEvent {
  final int taskStatusId;
  FetchTaskStatus(this.taskStatusId);
}

class FetchMoreTasks extends TaskEvent {
  final int statusId;
  final int currentPage;

  FetchMoreTasks(this.statusId, this.currentPage);
}
/*
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
*/
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
  final List<String>? filePaths; // Изменено на список путей к файлам
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
    this.filePaths, // Изменено на список путей к файлам
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
  final List<String>? filePaths; // Изменено на список путей к файлам
  final AppLocalizations localizations;  // Add this to your event
  final List<TaskFiles>? existingFiles; // Добавляем поле для существующих файлов


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
    this.filePaths, // Изменено на список путей к файлам
    required this.localizations,  // Add this to constructor
    this.existingFiles, // Добавляем в конструктор

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
// Event
class UpdateTaskStatusEdit extends TaskEvent {
  final int taskStatusId;
  final String name;
  final bool needsPermission;
  final bool finalStep;
  final bool checkingStep;
  final List<int> roleIds;
  final AppLocalizations localizations;

  UpdateTaskStatusEdit({
    required this.taskStatusId,
    required this.name,
    required this.needsPermission,
    required this.finalStep,
    required this.checkingStep,
    required this.roleIds,
    required this.localizations,
  });
}