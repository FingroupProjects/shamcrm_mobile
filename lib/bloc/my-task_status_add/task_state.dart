// bloc/task_status/task_status_state.dart
import 'package:equatable/equatable.dart';

abstract class MyTaskStatusState extends Equatable {
  const MyTaskStatusState();

  @override
  List<Object> get props => [];
}

class MyTaskStatusInitial extends MyTaskStatusState {}
class MyTaskStatusLoading extends MyTaskStatusState {}
class MyTaskStatusCreated extends MyTaskStatusState {
  final String message;
  const MyTaskStatusCreated(this.message);
  @override
  List<Object> get props => [message];
}
class MyTaskStatusError extends MyTaskStatusState {
  final String message;
  const MyTaskStatusError(this.message);
  @override
  List<Object> get props => [message];
}
