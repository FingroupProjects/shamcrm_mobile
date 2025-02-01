import 'package:crm_task_manager/models/my-task_model.dart';

abstract class MyTaskState {}

class MyTaskInitial extends MyTaskState {}

class MyTaskLoading extends MyTaskState {}

class MyTaskLoaded extends MyTaskState {
  final List<MyTaskStatus> taskStatuses;
  final Map<int, int> taskCounts;

  MyTaskLoaded(this.taskStatuses, {Map<int, int>? taskCounts})
      : this.taskCounts = taskCounts ?? {};

  // Добавляем метод copyWith
  MyTaskLoaded copyWith({
    List<MyTaskStatus>? taskStatuses,
    Map<int, int>? taskCounts,
  }) {
    return MyTaskLoaded(
      taskStatuses ?? this.taskStatuses,
      taskCounts: taskCounts ?? this.taskCounts,
    );
  }
}

class MyTaskDataLoaded extends MyTaskState {
  final List<MyTask> tasks;
  final int currentPage;
  final bool allMyTasksFetched;
  final Map<int, int> taskCounts;

  MyTaskDataLoaded(this.tasks,
      {this.currentPage = 1, this.allMyTasksFetched = false, Map<int, int>? taskCounts})
      : taskCounts = taskCounts ?? {};

  MyTaskDataLoaded merge(List<MyTask> newMyTasks) {
    return MyTaskDataLoaded(
      tasks + newMyTasks,
      currentPage: currentPage,
      taskCounts: taskCounts,
    );
  }

  // Метод для обновления taskCounts
  MyTaskDataLoaded updateMyTaskCounts(Map<int, int> newMyTaskCounts) {
    return MyTaskDataLoaded(
      tasks,
      currentPage: currentPage,
      taskCounts: newMyTaskCounts,
    );
  }
}

class MyTaskError extends MyTaskState {
  final String message;
  MyTaskError(this.message);
}

class MyTaskSuccess extends MyTaskState {
  final String message;
  MyTaskSuccess(this.message);
}

class MyTaskDeleted extends MyTaskState {
  final String message;
  MyTaskDeleted(this.message);
}

class MyTaskStatusDeleted extends MyTaskState {
  final String message;
  MyTaskStatusDeleted(this.message);
}

class MyTaskStatusLoaded extends MyTaskState {
  final MyTaskStatus myTaskStatus;
  MyTaskStatusLoaded(this.myTaskStatus);
}


// State для успешного обновления статуса лида
class MyTaskStatusUpdatedEdit extends MyTaskState {
  final String message;

  MyTaskStatusUpdatedEdit(this.message);
}
