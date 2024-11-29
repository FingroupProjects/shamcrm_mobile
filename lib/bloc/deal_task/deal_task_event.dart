abstract class DealTasksEvent {}

class FetchDealTasks extends DealTasksEvent {
  final int taskId;

  FetchDealTasks(this.taskId);
}
