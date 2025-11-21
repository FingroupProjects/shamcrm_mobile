import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/dealStats/dealStats_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/deal_stats_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:crm_task_manager/screens/dashboard/CACHE/deal_stats_cache.dart';

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

      // Попытка загрузить данные из кеша
      final cachedData = await DealStatsCache.getDealStatsData();
      if (cachedData != null) {
        emit(DealStatsLoaded(dealStatsData: DealStatsResponse(data: cachedData)));
      } else {
      }

      // Проверка интернет-соединения
      if (await _checkInternetConnection()) {
        final serverData = await apiService.getDealStatsData();

        // Обновление кеша, если данные отличаются
        if (cachedData == null || cachedData != serverData.data) {

          await DealStatsCache.saveDealStatsData(serverData.data);
        } else {
        }

        emit(DealStatsLoaded(dealStatsData: serverData));
      } else if (cachedData == null) {
        emit(DealStatsError(message: 'Нет подключения к интернету и данных в кеше.'));
      }
    } catch (e) {
      emit(DealStatsError(message: e.toString()));
    }
  }
}
