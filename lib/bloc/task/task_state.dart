import 'package:crm_task_manager/models/task_model.dart';

abstract class TaskState {}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<TaskStatus> taskStatuses;

  TaskLoaded(this.taskStatuses);
}

class TaskDataLoaded extends TaskState {
  final List<Task> tasks;
  final int currentPage;

  TaskDataLoaded(this.tasks, {this.currentPage = 1});

  // Метод для объединения с новыми сделками
  TaskDataLoaded merge(List<Task> newTasks) {
    return TaskDataLoaded([...tasks, ...newTasks],
        currentPage: currentPage + 1);
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