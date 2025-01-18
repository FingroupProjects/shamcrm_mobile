import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/my-task_status_add/task_event.dart';
import 'package:crm_task_manager/bloc/my-task_status_add/task_state.dart';

class MyTaskStatusBloc extends Bloc<MyTaskStatusEvent, MyTaskStatusState> {
  final ApiService apiService;

  MyTaskStatusBloc(this.apiService) : super(MyTaskStatusInitial()) {
    on<CreateMyTaskStatusAdd>(_onCreateMyTaskStatusAdd);
  }

  Future<void> _onCreateMyTaskStatusAdd(
    CreateMyTaskStatusAdd event,
    Emitter<MyTaskStatusState> emit,
  ) async {
    emit(MyTaskStatusLoading());

    if (await _checkInternetConnection()) {
      try {
        final response = await apiService.CreateMyTaskStatusAdd(
          statusName: event.statusName,
          finalStep: event.finalStep,
        );
        
        if (response['success']) {
          emit(MyTaskStatusCreated(response['message']));
        } else {
          emit(MyTaskStatusError(response['message']));
        }
      } catch (e) {
        emit(MyTaskStatusError('Ошибка при создании статуса'));
      }
    } else {
      emit(MyTaskStatusError('Нет подключения к интернету'));
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}