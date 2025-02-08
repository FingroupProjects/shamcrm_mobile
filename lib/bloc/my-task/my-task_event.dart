import 'package:crm_task_manager/models/my-taskbyId_model.dart';
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
  final List<String>? filePaths; // Изменено на список путей к файлам
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
    this.filePaths, // Изменено на список путей к файлам
    this.setPush = false, // Add this line with default value
    required this.localizations,
  });
}

/*class CreateMyTask extends MyTaskEvent {
  final String name;
  final int statusId;
  final int? taskStatusId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;
  final List<String>? filePaths; // Изменено на список путей к файлам
  final List<Map<String, String>>? customFields;
  final bool setPush; // Добавлено
  final AppLocalizations localizations;

  CreateMyTask({
    required this.name,
    required this.statusId,
    required this.taskStatusId,
    this.startDate,
    this.endDate,
    this.description,
    this.customFields,
    this.filePaths, // Изменено на список путей к файлам
    this.setPush = false, // Добавлено с значением по умолчанию
    required this.localizations,
  });
}
*/
class UpdateMyTask extends MyTaskEvent {
  final int taskId;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;
  final int taskStatusId;
  final List<String>? filePaths; // Изменено на список путей к файлам
  final bool setPush; // Add this line
  final AppLocalizations localizations;
  final List<MyTaskFiles>?
      existingFiles; // Добавляем поле для существующих файлов

  UpdateMyTask({
    required this.taskId,
    required this.name,
    this.startDate,
    this.endDate,
    this.description,
    required this.taskStatusId,
    this.filePaths, // Изменено на список путей к файлам
    this.setPush = false, // Add this line with default value
    required this.localizations,
    this.existingFiles, // Добавляем в конструктор
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
