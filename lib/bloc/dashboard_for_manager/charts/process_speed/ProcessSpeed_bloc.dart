import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/process_speed/ProcessSpeed_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/process_speed/ProcessSpeed_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProcessSpeedBlocManager extends Bloc<ProcessSpeedEventManager, ProcessSpeedStateManager> {
  final ApiService _apiService;

  ProcessSpeedBlocManager(this._apiService) : super(ProcessSpeedInitialManager()) {
    on<LoadProcessSpeedDataManager>(_onLoadProcessSpeedDataManager);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _onLoadProcessSpeedDataManager(
    LoadProcessSpeedDataManager event,
    Emitter<ProcessSpeedStateManager> emit,
  ) async {
    try {
      emit(ProcessSpeedLoadingManager());

      // Check for internet connection
      if (await _checkInternetConnection()) {
        final processSpeedData = await _apiService.getProcessSpeedDataManager();
        emit(ProcessSpeedLoadedManager(processSpeedData: processSpeedData));
      } else {
        emit(ProcessSpeedErrorManager(message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
      }
    } catch (e) {
      emit(ProcessSpeedErrorManager(message: "Ошибка загрузки данных графика Скорость обработки"));
    }
  }
}
