import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealStatsBloc extends Bloc<DealStatsEvent, DealStatsState> {
  final ApiService apiService;

  DealStatsBloc(this.apiService) : super(DealStatsInitial()) {
    on<LoadDealStatsData>(_onLoadDealStatsData);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _onLoadDealStatsData(
    LoadDealStatsData event,
    Emitter<DealStatsState> emit,
  ) async {
    try {
      emit(DealStatsLoading());

      // Check for internet connection
      if (await _checkInternetConnection()) {
        final dealStatsData = await apiService.getDealStatsData();
        emit(DealStatsLoaded(dealStatsData: dealStatsData));
      } else {
        emit(DealStatsError(message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
      }
    } catch (e) {
      emit(DealStatsError(message: e.toString()));
    }
  }
}
