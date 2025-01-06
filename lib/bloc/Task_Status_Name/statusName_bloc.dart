import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_event.dart';
import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskStatusNameBloc extends Bloc<StatusNameEvent, StatusNameState> {
  final ApiService apiService;

  TaskStatusNameBloc(this.apiService) : super(StatusNameInitial()) {
    on<FetchStatusNames>((event, emit) async {
      emit(StatusNameLoading());

      if (await _checkInternetConnection()) {
        try {
          final statuses = await apiService.getStatusName();
          print('Полученные статусы в блоке: $statuses');

          emit(StatusNameLoaded(statuses));
        } catch (e) {
          print('Ошибка при загрузке статусов!'); // For debugging
          emit(StatusNameError('Ошибка при загрузке имен статусов!'));
        }
      } else {
        emit(StatusNameError('Нет подключения к интернету'));
      }
    });
  }

  // Method to check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      print('Нет интернета!'); // For debugging
      return false;
    }
  }
}
