
import 'package:crm_task_manager/models/user_model.dart';
import 'package:equatable/equatable.dart';

abstract class UserTaskState extends Equatable {
  const UserTaskState();

  @override
  List<Object> get props => [];
}

class UserTaskInitial extends UserTaskState {}

class UserTaskLoading extends UserTaskState {}

class UserTaskLoaded extends UserTaskState {
  final List<UserTask> users;

  const UserTaskLoaded(this.users);

  @override
  List<Object> get props => [users];
}

class UserTaskError extends UserTaskState {
  final String message;

  const UserTaskError(this.message);

  @override
  List<Object> get props => [message];
}
