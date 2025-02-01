// my-task_status_add/task_event.dart
import 'package:equatable/equatable.dart';

abstract class MyTaskStatusEvent extends Equatable {
  const MyTaskStatusEvent();

  @override
  List<Object?> get props => [];
}

class CreateMyTaskStatusAdd extends MyTaskStatusEvent {
  final String statusName;

  const CreateMyTaskStatusAdd({
    required this.statusName,
  });

  @override
  List<Object> get props => [statusName];
}
