abstract class TaskEvent {}

class FetchTaskStatuses extends TaskEvent {}

class FetchTasks extends TaskEvent {
  final int statusId;

  FetchTasks(this.statusId);
}

class FetchMoreTasks extends TaskEvent {
  final int statusId;
  final int currentPage;

  FetchMoreTasks(this.statusId, this.currentPage);
}

class CreateTaskStatus extends TaskEvent {
  final String name;
  final String color;

  CreateTaskStatus({
    required this.name,
    required this.color,
  });
}

class CreateTask extends TaskEvent {
  final String name;
  final int taskStatusId;
  final int? managerId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sum;

  final String? description;
  final int? organizationId;

  CreateTask({
    required this.name,
    required this.taskStatusId,
    this.managerId,
    this.startDate,
    this.endDate,
    required this.sum,
    this.description,
    this.organizationId,
  });
}

class UpdateTask extends TaskEvent {
  final int taskId;
  final String name;
  final int taskStatusId;
  final int? managerId;
  final String? description;
  final int? organizationId;

  UpdateTask({
    required this.taskId,
    required this.name,
    required this.taskStatusId,
    this.managerId,
    this.description,
    this.organizationId,
  });
}
