
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

// // bloc/user/user_state.dart
// import 'package:crm_task_manager/models/user_add_task_model.dart';
// import 'package:equatable/equatable.dart';

// abstract class UserState extends Equatable {
//   const UserState();

//   @override
//   List<Object> get props => [];
// }

// class UserInitial extends UserState {}

// class UserLoading extends UserState {}

// class UserLoaded extends UserState {
//   final List<UserTaskAdd> users;

//   const UserLoaded(this.users);

//   @override
//   List<Object> get props => [users];
// }

// class UserError extends UserState {
//   final String message;

//   const UserError(this.message);

//   @override
//   List<Object> get props => [message];
// }
