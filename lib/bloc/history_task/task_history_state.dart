import 'package:crm_task_manager/models/history_model_task.dart';
import 'package:equatable/equatable.dart';

abstract class HistoryStateTask extends Equatable {
  @override
  List<Object?> get props => [];
}

class HistoryInitialTask extends HistoryStateTask {}

class HistoryLoadingTask extends HistoryStateTask {}

class HistoryLoadedTask extends HistoryStateTask {
  final List<TaskHistory> taskHistory;

  HistoryLoadedTask(this.taskHistory);

  @override
  List<Object?> get props => [taskHistory];
}

class HistoryErrorTask extends HistoryStateTask {
  final String message;

  HistoryErrorTask(this.message);

  @override
  List<Object?> get props => [message];
}
