import 'package:crm_task_manager/models/history_model_my-task.dart';
import 'package:crm_task_manager/models/history_model_task.dart';
import 'package:equatable/equatable.dart';

abstract class HistoryStateMyTask extends Equatable {
  @override
  List<Object?> get props => [];
}

class HistoryInitialMyTask extends HistoryStateMyTask {}

class HistoryLoadingMyTask extends HistoryStateMyTask {}

class HistoryLoadedMyTask extends HistoryStateMyTask {
  final List<MyTaskHistory> taskHistory;

  HistoryLoadedMyTask(this.taskHistory);

  @override
  List<Object?> get props => [taskHistory];
}

class HistoryErrorMyTask extends HistoryStateMyTask {
  final String message;

  HistoryErrorMyTask(this.message);

  @override
  List<Object?> get props => [message];
}
