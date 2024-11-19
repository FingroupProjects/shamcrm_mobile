// bloc/task_status/task_status_state.dart
import 'package:equatable/equatable.dart';

abstract class TaskStatusState extends Equatable {
  const TaskStatusState();

  @override
  List<Object> get props => [];
}

class TaskStatusInitial extends TaskStatusState {}
class TaskStatusLoading extends TaskStatusState {}
class TaskStatusCreated extends TaskStatusState {
  final String message;
  const TaskStatusCreated(this.message);
  @override
  List<Object> get props => [message];
}
class TaskStatusError extends TaskStatusState {
  final String message;
  const TaskStatusError(this.message);
  @override
  List<Object> get props => [message];
}
