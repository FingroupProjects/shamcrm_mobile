import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchTaskHistory extends HistoryEvent {
  final int taskId;

  FetchTaskHistory(this.taskId);

  @override
  List<Object?> get props => [taskId];
}
