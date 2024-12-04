import 'package:crm_task_manager/models/deal_task_model.dart';

abstract class DealTasksState {}

class DealTasksInitial extends DealTasksState {}

class DealTasksLoading extends DealTasksState {}

class DealTasksLoaded extends DealTasksState {
  final List<DealTask> tasks;

  DealTasksLoaded(this.tasks);

}

class DealTasksError extends DealTasksState {
  final String message;

  DealTasksError(this.message);
}

class DealTasksSuccess extends DealTasksState {
  final String message;

  DealTasksSuccess(this.message);
}

class DealTasksDeleted extends DealTasksState {
  final String message;

  DealTasksDeleted(this.message);
}
