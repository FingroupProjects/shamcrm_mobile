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
  final int statusId;
  final String? priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? projectId;
  final int? userId;
  final String? description;

  CreateTask({
    required this.name,
    required this.statusId,
    this.priority,
    this.startDate,
    this.endDate,
    this.projectId,
    this.userId,
    this.description,
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
  final int? userId;
  final String? description;

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
  });
}