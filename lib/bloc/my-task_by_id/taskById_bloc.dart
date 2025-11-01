import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/my-task_by_id/taskById_event.dart';
import 'package:crm_task_manager/bloc/my-task_by_id/taskById_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyTaskByIdBloc extends Bloc<MyTaskByIdEvent, MyTaskByIdState> {
  final ApiService apiService;

  MyTaskByIdBloc(this.apiService) : super(MyTaskByIdInitial()) {
    on<FetchMyTaskByIdEvent>(_getMyTaskById);
  }

  Future<void> _getMyTaskById(FetchMyTaskByIdEvent event, Emitter<MyTaskByIdState> emit) async {
  emit(MyTaskByIdLoading());

  if (await _checkInternetConnection()) {
    try {
      final task = await apiService.getMyTaskById(event.taskId);
      if (task != null) {
        emit(MyTaskByIdLoaded(task));
      } else {
        emit(MyTaskByIdError('Задача не найдена'));
      }
    } catch (e) {
      //print('Ошибка при загрузке задачи: $e'); // Добавим вывод ошибки
      emit(MyTaskByIdError('Не удалось загрузить данные задачи: ${e.toString()}'));
    }
  } else {
    emit(MyTaskByIdError('Нет подключения к интернету'));
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
