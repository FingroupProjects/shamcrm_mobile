import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

abstract class MyTaskEvent {}

class FetchMyTaskStatuses extends MyTaskEvent {}

class FetchMyTasks extends MyTaskEvent {
  final int statusId;
  final String? query; // Добавьте параметр для поиска

  FetchMyTasks(
    this.statusId, {
    this.query,
  });
}

class FetchMoreMyTasks extends MyTaskEvent {
  final int statusId;
  final int currentPage;

  FetchMoreMyTasks(this.statusId, this.currentPage);
}

class CreateMyTask extends MyTaskEvent {
  final String name;
  final int statusId;
  final int? taskStatusId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;
  final String? filePath;
  final List<Map<String, String>>? customFields;
  final bool setPush; // Add this line
  final AppLocalizations localizations; 

  CreateMyTask({
    required this.name,
    required this.statusId,
    required this.taskStatusId,
    this.startDate,
    this.endDate,
    this.description,
    this.customFields,
    this.filePath,
    this.setPush = false, // Add this line with default value
    required this.localizations,
  });
}

class UpdateMyTask extends MyTaskEvent {
  final int taskId;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;
  final int taskStatusId;
  final String? filePath;
  final bool setPush; // Add this line
   final AppLocalizations localizations; 

  UpdateMyTask({
    required this.taskId,
    required this.name,
    this.startDate,
    this.endDate,
    this.description,
    required this.taskStatusId,
    this.filePath,
    this.setPush = false, // Add this line with default value
    required this.localizations,

  });
}

class CreateMyTaskStatus extends MyTaskEvent {
  final int taskStatusNameId;
  final int organizationId;
  final bool needsPermission;
   final AppLocalizations localizations; 

  CreateMyTaskStatus({
    required this.taskStatusNameId,
    required this.organizationId,
    required this.needsPermission,
    required this.localizations,

  });
}

class DeleteMyTask extends MyTaskEvent {
  final int taskId;
   final AppLocalizations localizations; 

  DeleteMyTask(
    this.taskId,
    this.localizations,
    );
}

class DeleteMyTaskStatuses extends MyTaskEvent {
  final int taskStatusId;
   final AppLocalizations localizations; 

  DeleteMyTaskStatuses(
    this.taskStatusId,
    this.localizations,
    );
}

class FetchMyTaskStatus extends MyTaskEvent {
  final int myTaskStatusId;
  FetchMyTaskStatus(this.myTaskStatusId);
}

// Event для изменения статуса лида
class UpdateMyTaskStatusEdit extends MyTaskEvent {
  final int myTaskStatusId;
  final String title;
  final AppLocalizations localizations;

  UpdateMyTaskStatusEdit(
    this.myTaskStatusId,
    this.title,
    this.localizations,
  );
}
