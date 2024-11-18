import 'package:crm_task_manager/models/taskbyId_model.dart';

abstract class TaskByIdState {}

class TaskByIdInitial extends TaskByIdState {}

class TaskByIdLoading extends TaskByIdState {}

class TaskByIdLoaded extends TaskByIdState {
  final TaskById task;
  TaskByIdLoaded(this.task);
}

class TaskByIdError extends TaskByIdState {
  final String message;
  TaskByIdError(this.message);
}
