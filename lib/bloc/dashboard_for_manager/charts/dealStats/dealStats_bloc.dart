import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/dealStats/dealStats_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/dealStats/dealStats_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealStatsManagerBloc extends Bloc<DealStatsEventManager, DealStatsStateManager> {
  final ApiService apiService;

  DealStatsManagerBloc(this.apiService) : super(DealStatsInitialManager()) {
    on<LoadDealStatsManagerData>(_onLoadDealStatsManagerData);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _onLoadDealStatsManagerData(
    LoadDealStatsManagerData event,
    Emitter<DealStatsStateManager> emit,
  ) async {
    try {
      emit(DealStatsLoadingManager());

      // Check for internet connection
      if (await _checkInternetConnection()) {
        final dealStatsData = await apiService.getDealStatsManagerData();
        emit(DealStatsLoadedManager(dealStatsData: dealStatsData));
      } else {
        emit(DealStatsErrorManager(message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
      }
    } catch (e) {
      emit(DealStatsErrorManager(message: e.toString()));
    }
  }
}
