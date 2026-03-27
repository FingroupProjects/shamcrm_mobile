

import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/dealStats/dealStats_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/dealStats/dealStats_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/deal_stats_model.dart';
import 'package:crm_task_manager/screens/dashboard_for_manager/CACHE/deal_stats_manager_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealStatsManagerBloc extends Bloc<DealStatsEventManager, DealStatsStateManager> {
  final ApiService apiService;

  DealStatsManagerBloc(this.apiService) : super(DealStatsInitialManager()) {
    on<LoadDealStatsManagerData>(_onLoadDealStatsData);
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
    LoadDealStatsManagerData event,
    Emitter<DealStatsStateManager> emit,
  ) async {
    try {
      emit(DealStatsLoadingManager());

      // Попытка загрузить данные из кеша
      final cachedData = await DealStatsCacheManager.getDealStatsDataManager();
      if (cachedData != null) {
        emit(DealStatsLoadedManager(dealStatsData: DealStatsResponseManager(data: cachedData)));
      } else {
      }

      // Проверка интернет-соединения
      if (await _checkInternetConnection()) {
        final serverData = await apiService.getDealStatsManagerData();

        // Обновление кеша, если данные отличаются
        if (cachedData == null || cachedData != serverData.data) {
          await DealStatsCacheManager.saveDealStatsDataManager(serverData.data);
        } else {
        }

        emit(DealStatsLoadedManager(dealStatsData: serverData));
      } else if (cachedData == null) {
        emit(DealStatsErrorManager(message: 'Нет подключения к интернету и данных в кеше.'));
      }
    } catch (e) {
      emit(DealStatsErrorManager(message: e.toString()));
    }
  }
}