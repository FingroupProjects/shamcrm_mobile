

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task_status_add/task_event.dart';
import 'package:crm_task_manager/bloc/task_status_add/task_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskStatusBloc extends Bloc<TaskStatusEvent, TaskStatusState> {
  final ApiService apiService;

  TaskStatusBloc(this.apiService) : super(TaskStatusInitial()) {
    on<CreateTaskStatusAdd>(_onCreateTaskStatusAdd);
    
  }

  Future<void> _onCreateTaskStatusAdd(
    CreateTaskStatusAdd event,
    Emitter<TaskStatusState> emit,
  ) async {
    emit(TaskStatusLoading());
    try {
      final response = await apiService.CreateTaskStatusAdd(
        taskStatusNameId: event.taskStatusNameId,
        projectId: event.projectId,
        organizationId: event.organizationId,
        needsPermission: event.needsPermission,
        roleIds: event.roleIds,
      );
      
      if (response['success']) {
        emit(TaskStatusCreated(response['message']));
      } else {
        emit(TaskStatusError(response['message']));
      }
    } catch (e) {
      emit(TaskStatusError('Ошибка при создании статуса: $e'));
    }
  }
}
