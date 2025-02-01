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
        emit(MyTaskByIdLoaded(task));
      } catch (e) {
        print('Ошибка при загрузке задачи!'); // For debugging
        emit(MyTaskByIdError('Не удалось загрузить данные задачи!'));
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
