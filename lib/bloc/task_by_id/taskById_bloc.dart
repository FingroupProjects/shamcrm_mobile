import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_event.dart';
import 'package:crm_task_manager/bloc/task_by_id/taskById_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskByIdBloc extends Bloc<TaskByIdEvent, TaskByIdState> {
  final ApiService apiService;

  TaskByIdBloc(this.apiService) : super(TaskByIdInitial()) {
    on<FetchTaskByIdEvent>(_getTaskById);
  }

Future<void> _getTaskById(FetchTaskByIdEvent event, Emitter<TaskByIdState> emit) async {
  emit(TaskByIdLoading());

  try {
    final task = await apiService.getTaskById(event.taskId);
    emit(TaskByIdLoaded(task));
  } catch (e) {
    emit(TaskByIdError('Не удалось загрузить данные задачи: ${e.toString()}'));
  }
}

}
