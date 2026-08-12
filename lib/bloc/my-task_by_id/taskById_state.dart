import 'package:crm_task_manager/models/my_task/my-taskbyId_model.dart';
import 'package:crm_task_manager/models/task/taskbyId_model.dart';

abstract class MyTaskByIdState {}

class MyTaskByIdInitial extends MyTaskByIdState {}

class MyTaskByIdLoading extends MyTaskByIdState {}

class MyTaskByIdLoaded extends MyTaskByIdState {
  final MyTaskById task;
  MyTaskByIdLoaded(this.task);
}

class MyTaskByIdError extends MyTaskByIdState {
  final String message;
  MyTaskByIdError(this.message);
}
