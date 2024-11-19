// bloc/task_status/task_status_event.dart
import 'package:equatable/equatable.dart';

abstract class TaskStatusEvent extends Equatable {
  const TaskStatusEvent();

  @override
  List<Object?> get props => [];
}

class CreateTaskStatus extends TaskStatusEvent {
  final int taskStatusNameId;
  final int projectId;
  final int organizationId;
  final bool needsPermission;
  final List<int>? roleIds;

  const CreateTaskStatus({
    required this.taskStatusNameId,
    required this.projectId,
    required this.organizationId,
    required this.needsPermission,
    this.roleIds,
  });

  @override
  List<Object?> get props => [
        taskStatusNameId,
        projectId,
        organizationId,
        needsPermission,
        roleIds,
      ];
}
