
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

  CreateMyTask({
    required this.name,
    required this.statusId,
    required this.taskStatusId,
    this.startDate,
    this.endDate,
    this.description,
    this.customFields,
    this.filePath,
  });
}

class UpdateMyTask extends MyTaskEvent {
  final int taskId;
  final String name;
  final int statusId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;
  final int taskStatusId;
  final List<Map<String, String>>? customFields;

  final String? filePath;

  UpdateMyTask({
    required this.taskId,
    required this.name,
    required this.statusId,
    this.startDate,
    this.endDate,
    this.description,
    required this.taskStatusId,
    this.customFields,
    this.filePath,
  });
}

class CreateMyTaskStatus extends MyTaskEvent {
  final int taskStatusNameId;
  final int organizationId;
  final bool needsPermission;

  CreateMyTaskStatus({
    required this.taskStatusNameId,
    required this.organizationId,
    required this.needsPermission,
  });
}

class DeleteMyTask extends MyTaskEvent {
  final int taskId;

  DeleteMyTask(this.taskId);
}

class DeleteMyTaskStatuses extends MyTaskEvent {
  final int taskStatusId;

  DeleteMyTaskStatuses(this.taskStatusId);
}
