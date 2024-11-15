
import 'package:crm_task_manager/models/task_model.dart';

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
  final bool? hasAccess;
  final bool? isFinalStage;
  final String? roleId;

  CreateTaskStatus({
    required this.name,
    required this.color,
    this.hasAccess,
    this.isFinalStage,
    this.roleId,
    
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
  final int? userId;
  final String? description;
  // final TaskFile? file;
  
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
    // this.file,
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
  final int taskStatusId;
  // final TaskFile? file;

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
    // this.file,
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