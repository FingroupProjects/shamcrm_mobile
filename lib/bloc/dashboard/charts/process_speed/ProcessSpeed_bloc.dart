import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProcessSpeedBloc extends Bloc<ProcessSpeedEvent, ProcessSpeedState> {
  final ApiService _apiService;

  ProcessSpeedBloc(this._apiService) : super(ProcessSpeedInitial()) {
    on<LoadProcessSpeedData>(_onLoadProcessSpeedData);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _onLoadProcessSpeedData(
    LoadProcessSpeedData event,
    Emitter<ProcessSpeedState> emit,
  ) async {
    try {
      emit(ProcessSpeedLoading());

      // Check for internet connection
      if (await _checkInternetConnection()) {
        final processSpeedData = await _apiService.getProcessSpeedData();
        emit(ProcessSpeedLoaded(processSpeedData: processSpeedData));
      } else {
        emit(ProcessSpeedError(message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
      }
    } catch (e) {
      emit(ProcessSpeedError(message: "Ошибка загрузки данных графика Скорость обработки"));
    }
  }
}
