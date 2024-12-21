// States
import 'package:crm_task_manager/models/dashboard_charts_models/user_task%20_model.dart';

abstract class TaskCompletionState {}

class TaskCompletionInitial extends TaskCompletionState {}

class TaskCompletionLoading extends TaskCompletionState {}

class TaskCompletionLoaded extends TaskCompletionState {
  final List<UserTaskCompletion> data;
  TaskCompletionLoaded({required this.data});
}

class TaskCompletionError extends TaskCompletionState {
  final String message;
  TaskCompletionError({required this.message});
}