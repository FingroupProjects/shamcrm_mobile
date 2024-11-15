abstract class TaskByIdEvent {}

class FetchTaskByIdEvent extends TaskByIdEvent {
  final int taskId;
  FetchTaskByIdEvent({required this.taskId});
}
