import 'package:crm_task_manager/models/overdue_task_response.dart';

abstract class UserOverdueTaskState {}

class UserOverdueTaskInitial extends UserOverdueTaskState {}

class UserOverdueTaskLoading extends UserOverdueTaskState {}

class UserOverdueTaskLoaded extends UserOverdueTaskState {
  final OverdueTasksResponse data;

  UserOverdueTaskLoaded({required this.data});
}

class UserOverdueTaskError extends UserOverdueTaskState {
  final String message;

  UserOverdueTaskError({required this.message});
}