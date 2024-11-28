import 'package:crm_task_manager/models/chatTaskProfile_model.dart';
import 'package:equatable/equatable.dart';

abstract class TaskProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TaskProfileInitial extends TaskProfileState {}

class TaskProfileLoading extends TaskProfileState {}

class TaskProfileLoaded extends TaskProfileState {
  final TaskProfile profile;

  TaskProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class TaskProfileError extends TaskProfileState {
  final String error;

  TaskProfileError(this.error);

  @override
  List<Object?> get props => [error];
}
