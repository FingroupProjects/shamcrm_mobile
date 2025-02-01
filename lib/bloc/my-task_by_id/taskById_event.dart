abstract class MyTaskByIdEvent {}

class FetchMyTaskByIdEvent extends MyTaskByIdEvent {
  final int taskId;
  FetchMyTaskByIdEvent({required this.taskId});
}
