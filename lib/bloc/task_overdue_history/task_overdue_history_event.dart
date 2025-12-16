import 'package:equatable/equatable.dart';

abstract class TaskOverdueHistoryEvent extends Equatable {
  const TaskOverdueHistoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchTaskOverdueHistory extends TaskOverdueHistoryEvent {
  final int taskId;

  const FetchTaskOverdueHistory(this.taskId);

  @override
  List<Object?> get props => [taskId];
}
