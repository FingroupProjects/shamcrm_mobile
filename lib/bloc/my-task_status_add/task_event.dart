// my-task_status_add/task_event.dart
import 'package:equatable/equatable.dart';

abstract class MyTaskStatusEvent extends Equatable {
  const MyTaskStatusEvent();

  @override
  List<Object?> get props => [];
}

class CreateMyTaskStatusAdd extends MyTaskStatusEvent {
  final String statusName;
    final bool? finalStep; // Добавлено поле finalStep

  const CreateMyTaskStatusAdd({
    required this.statusName,
        this.finalStep, // Инициализация нового поля

  });

  @override
  List<Object?> get props => [
   statusName,  
   finalStep, // Добавлено поле в список props
];
}
