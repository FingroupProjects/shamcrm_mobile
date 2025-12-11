import 'package:crm_task_manager/models/task_overdue_history_model.dart';
import 'package:equatable/equatable.dart';

abstract class TaskOverdueHistoryState extends Equatable {
  const TaskOverdueHistoryState();

  @override
  List<Object?> get props => [];
}

class TaskOverdueHistoryInitial extends TaskOverdueHistoryState {}

class TaskOverdueHistoryLoading extends TaskOverdueHistoryState {}

class TaskOverdueHistoryLoaded extends TaskOverdueHistoryState {
  final List<TaskOverdueHistoryItem> history;

  const TaskOverdueHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class TaskOverdueHistoryError extends TaskOverdueHistoryState {
  final String message;

  const TaskOverdueHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
