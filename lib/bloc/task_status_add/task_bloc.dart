import 'dart:io';

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

    if (await _checkInternetConnection()) {
      try {
        final response = await apiService.CreateTaskStatusAdd(
          taskStatusNameId: event.taskStatusNameId,
          projectId: event.projectId,
          needsPermission: event.needsPermission,
          roleIds: event.roleIds,
          finalStep: event.finalStep,
        );
        
        if (response['success']) {
          emit(TaskStatusCreated(response['message']));
        } else {
          emit(TaskStatusError(response['message']));
        }
      } catch (e) {
        print('Ошибка при создании статуса: $e'); // For debugging
        emit(TaskStatusError('Ошибка при создании статуса!'));
      }
    } else {
      emit(TaskStatusError('Нет подключения к интернету'));
    }
  }

  // Method to check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      print('Нет интернета: $e'); // For debugging
      return false;
    }
  }
}
