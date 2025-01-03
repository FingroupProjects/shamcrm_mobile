import 'dart:io';

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

    if (await _checkInternetConnection()) {
      try {
        final task = await apiService.getTaskById(event.taskId);
        emit(TaskByIdLoaded(task));
      } catch (e) {
        print('Ошибка при загрузке задачи!'); // For debugging
        emit(TaskByIdError('Не удалось загрузить данные задачи!'));
      }
    } else {
      emit(TaskByIdError('Нет подключения к интернету'));
    }
  }

  // Method to check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      return false;
    }
  }
}
