import 'package:crm_task_manager/models/task_model.dart';

abstract class TaskState {}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<TaskStatus> taskStatuses;
  final Map<int, int> taskCounts;

  TaskLoaded(this.taskStatuses, {Map<int, int>? taskCounts})
      : this.taskCounts = taskCounts ?? {};

  // Добавляем метод copyWith
  TaskLoaded copyWith({
    List<TaskStatus>? taskStatuses,
    Map<int, int>? taskCounts,
  }) {
    return TaskLoaded(
      taskStatuses ?? this.taskStatuses,
      taskCounts: taskCounts ?? this.taskCounts,
    );
  }
}

class TaskDataLoaded extends TaskState {
  final List<Task> tasks;
  final int currentPage;

  TaskDataLoaded(this.tasks, {this.currentPage = 1});

  TaskDataLoaded merge(List<Task> newTasks) {
    return TaskDataLoaded(
      tasks + newTasks,
      currentPage: currentPage,
    );
  }
}

class TaskError extends TaskState {
  final String message;
  TaskError(this.message);
}

class TaskSuccess extends TaskState {
  final String message;
  TaskSuccess(this.message);
}

class TaskDeleted extends TaskState {
  final String message;
  TaskDeleted(this.message);
}

class TaskStatusDeleted extends TaskState {
  final String message;
  TaskStatusDeleted(this.message);
}
