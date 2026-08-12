import 'package:crm_task_manager/models/task/task_model.dart';

abstract class TaskState {}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

// Новое состояние: показываем кэш, но индицируем что идёт обновление
class TaskLoadingWithCache extends TaskState {
  final List<TaskStatus> cachedStatuses;
  final Map<int, int> taskCounts;

  TaskLoadingWithCache(this.cachedStatuses, {Map<int, int>? taskCounts})
      : this.taskCounts = taskCounts ?? {};
}

class TaskLoaded extends TaskState {
  final List<TaskStatus> taskStatuses;
  final Map<int, int> taskCounts;

  TaskLoaded(this.taskStatuses, {Map<int, int>? taskCounts})
      : this.taskCounts = taskCounts ?? {};

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

class TaskStatusLoaded extends TaskState {
  final TaskStatus taskStatus;
  TaskStatusLoaded(this.taskStatus);
}

class TaskDataLoaded extends TaskState {
  final List<Task> tasks;
  final int currentPage;
  final Map<int, int> taskCounts;
  final bool isLoadingMore;

  TaskDataLoaded(
    this.tasks, {
    this.currentPage = 1,
    required this.taskCounts,
    this.isLoadingMore = false,
  });

  TaskDataLoaded merge(List<Task> newtasks) {
    return TaskDataLoaded(
      [...tasks, ...newtasks],
      currentPage: currentPage + 1,
      taskCounts: taskCounts,
      isLoadingMore: false,
    );
  }

  TaskDataLoaded copyWith({
    List<Task>? tasks,
    int? currentPage,
    Map<int, int>? taskCounts,
    bool? isLoadingMore,
  }) {
    return TaskDataLoaded(
      tasks ?? this.tasks,
      currentPage: currentPage ?? this.currentPage,
      taskCounts: taskCounts ?? this.taskCounts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TaskError extends TaskState {
  final String message;
  final bool hasCachedData; // Флаг наличия кэшированных данных
  
  TaskError(this.message, {this.hasCachedData = false});
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

class TaskStatusUpdatedEdit extends TaskState {
  final String message;
  TaskStatusUpdatedEdit(this.message);
}
