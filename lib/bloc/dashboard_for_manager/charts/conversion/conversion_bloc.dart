import 'dart:io';

import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/conversion/conversion_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/conversion/conversion_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class DashboardConversionBlocManager
    extends Bloc<DashboardConversionEventManager, DashboardConversionStateManager> {
  final ApiService _apiService;

  DashboardConversionBlocManager(this._apiService)
      : super(DashboardConversionInitialManager()) {
    on<LoadLeadConversionDataManager>(_onLoadLeadConversionData);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _onLoadLeadConversionData(
    LoadLeadConversionDataManager event,
    Emitter<DashboardConversionStateManager> emit,
  ) async {
    try {
      emit(DashboardConversionLoadingManager());

      // Check for internet connection
      if (await _checkInternetConnection()) {
        final leadConversionData = await _apiService.getLeadConversionDataManager();
        emit(DashboardConversionLoadedManager(leadConversionData: leadConversionData));
      } else {
        // emit(DashboardConversionError(message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
      }
    } catch (e) {
      emit(DashboardConversionErrorManager(message: e.toString()));
    }
  }
}
