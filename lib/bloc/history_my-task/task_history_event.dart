import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchMyTaskHistory extends HistoryEvent {
  final int taskId;

  FetchMyTaskHistory(this.taskId);

  @override
  List<Object?> get props => [taskId];
}
