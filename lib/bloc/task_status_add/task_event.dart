import 'package:equatable/equatable.dart';

abstract class TaskStatusEvent extends Equatable {
  const TaskStatusEvent();

  @override
  List<Object?> get props => [];
}

class CreateTaskStatusAdd extends TaskStatusEvent {
  final int taskStatusNameId;
  final int projectId;
  final bool needsPermission;
  final List<int>? roleIds;
  final bool? finalStep; // Добавлено поле finalStep


  const CreateTaskStatusAdd({
    required this.taskStatusNameId,
    required this.projectId,
    required this.needsPermission,
    this.roleIds,
    this.finalStep, // Инициализация нового поля
  });

  @override
  List<Object?> get props => [
        taskStatusNameId,
        projectId,
        needsPermission,
        roleIds,
        finalStep, // Добавлено поле в список props
      ];
}
