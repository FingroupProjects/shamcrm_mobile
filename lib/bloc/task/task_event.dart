import 'package:crm_task_manager/models/taskbyId_model.dart';
import 'package:crm_task_manager/models/file_helper.dart';
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
  final bool? overdue;
  final bool? hasFile;
  final bool? hasDeal;
  final bool? urgent;
  final DateTime? deadlinefromDate;
  final DateTime? deadlinetoDate;
  final List<int>? projectIds;
  final List<String>? authors;
  final String? department;
  final List<Map<String, dynamic>>? directoryValues; // Добавляем directoryValues

  FetchTasks(
    this.statusId, {
    this.query,
    this.userIds,
    this.statusIds,
    this.fromDate,
    this.toDate,
    this.deadlinefromDate,
    this.deadlinetoDate,
    this.overdue,
    this.hasFile,
    this.hasDeal,
    this.urgent,
    this.projectIds,
    this.authors,
    this.department,
    this.directoryValues, // Добавляем в конструктор
  });
}

class FetchTaskStatus extends TaskEvent {
  final int taskStatusId;
  FetchTaskStatus(this.taskStatusId);
}

class FetchMoreTasks extends TaskEvent {
  final int statusId;
  final int currentPage;
  final String? query;
  final List<int>? userIds;
  final int? statusIds;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool? overdue;
  final bool? hasFile;
  final bool? hasDeal;
  final bool? urgent;
  final DateTime? deadlinefromDate;
  final DateTime? deadlinetoDate;
  final List<int>? projectIds;
  final List<String>? authors;
  final String? department;
  final List<Map<String, dynamic>>? directoryValues; // Добавляем directoryValues

  FetchMoreTasks(
    this.statusId,
    this.currentPage, {
    this.query,
    this.userIds,
    this.statusIds,
    this.fromDate,
    this.toDate,
    this.deadlinefromDate,
    this.deadlinetoDate,
    this.overdue,
    this.hasFile,
    this.hasDeal,
    this.urgent,
    this.projectIds,
    this.authors,
    this.department,
    this.directoryValues, // Добавляем в конструктор
  });
}
class CreateTask extends TaskEvent {
  final String name;
  final int statusId;
  final int? taskStatusId;
  final int? priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? projectId;
  final List<int>? userId;
  final String? description;
  final List<Map<String, dynamic>>? customFields; // Изменяем тип
  final List<FileHelper>? files; // Изменено с List<String>? filePaths
  final List<Map<String, int>>? directoryValues;
  final AppLocalizations localizations;

  CreateTask({
    required this.name,
    required this.statusId,
    required this.taskStatusId,
    this.priority,
    this.startDate,
    this.endDate,
    this.projectId,
    this.userId,
    this.description,
    this.customFields,
    this.files,
    this.directoryValues,
    required this.localizations,
  });
} 
class UpdateTask extends TaskEvent {
  final int taskId;
  final String name;
  final int statusId;
  final int taskStatusId;
  final String? priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? projectId;
  final List<int>? userId;
  final String? description;
    final List<Map<String, dynamic>>? customFields; // Изменяем тип

  final List<String>? filePaths;
  final List<TaskFiles>? existingFiles;
  final List<Map<String, int>>? directoryValues; // Add for consistency
  final AppLocalizations localizations;

  UpdateTask({
    required this.taskId,
    required this.name,
    required this.statusId,
    required this.taskStatusId,
    this.priority,
    this.startDate,
    this.endDate,
    this.projectId,
    this.userId,
    this.description,
    this.customFields,
    this.filePaths,
    this.existingFiles,
    this.directoryValues,
    required this.localizations,
  });
}

class CreateTaskStatus extends TaskEvent {
  final int taskStatusNameId;
  final int projectId;
  final int organizationId;
  final bool needsPermission;
  final List<int>? roleIds;
  final AppLocalizations localizations; // Add this to your event

  CreateTaskStatus({
    required this.taskStatusNameId,
    required this.projectId,
    required this.organizationId,
    required this.needsPermission,
    this.roleIds,
    required this.localizations, // Add this to constructor
  });
}

class DeleteTask extends TaskEvent {
  final int taskId;
  final AppLocalizations localizations; // Add this to your event

  DeleteTask(
    this.taskId,
    this.localizations, // Add this to constructor
  );
}

class DeleteTaskStatuses extends TaskEvent {
  final int taskStatusId;
  final AppLocalizations localizations; // Add this to your event

  DeleteTaskStatuses(
    this.taskStatusId,
    this.localizations, // Add this to constructor
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
