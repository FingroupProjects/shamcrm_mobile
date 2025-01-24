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
  }) {print(taskCounts);
  print("-------------------------TaskLoaded------------------");
    return TaskLoaded(
      taskStatuses ?? this.taskStatuses,
      taskCounts: taskCounts ?? this.taskCounts,
    );
  }
}

class TaskDataLoaded extends TaskState {
  final List<Task> tasks;
  final int currentPage;
  final bool allTasksFetched;
  final Map<int, int> taskCounts;

  TaskDataLoaded(this.tasks,
      {this.currentPage = 1, this.allTasksFetched = false, Map<int, int>? taskCounts})
      : taskCounts = taskCounts ?? {};

  TaskDataLoaded merge(List<Task> newTasks) {print(taskCounts);
  print("-------------------------TaskLoaded------------------");
    return TaskDataLoaded(
      tasks + newTasks,
      currentPage: currentPage,
      taskCounts: taskCounts,
    );
  }

  // Метод для обновления taskCounts
  TaskDataLoaded updateTaskCounts(Map<int, int> newTaskCounts) {
    
    return TaskDataLoaded(
      tasks,
      currentPage: currentPage,
      taskCounts: newTaskCounts,
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

