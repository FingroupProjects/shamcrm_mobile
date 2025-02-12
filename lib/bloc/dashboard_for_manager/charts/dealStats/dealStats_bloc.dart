

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
      print("🔄 Начата загрузка данных...");

      // Попытка загрузить данные из кеша
      final cachedData = await DealStatsCacheManager.getDealStatsDataManager();
      if (cachedData != null) {
        print("📦 Найдены данные в кеше Deal Stats.");
        emit(DealStatsLoadedManager(dealStatsData: DealStatsResponseManager(data: cachedData)));
      } else {
        print("⚠️ Данные не найдены в кэше.");
      }

      // Проверка интернет-соединения
      if (await _checkInternetConnection()) {
        print("🌐 Интернет-соединение установлено. Загружаем данные с сервера...");
        final serverData = await apiService.getDealStatsManagerData();

        // Обновление кеша, если данные отличаются
        if (cachedData == null || cachedData != serverData.data) {
          print("🔄 СТАТИСТИКА СДЕЛОК Данные из кэша совпадают с сервером.");
          await DealStatsCacheManager.saveDealStatsDataManager(serverData.data);
        } else {
          print("✅ Кэш уже содержит актуальные данные.");
        }

        emit(DealStatsLoadedManager(dealStatsData: serverData));
      } else if (cachedData == null) {
        print("❌ Нет подключения к интернету и данных в кэше.");
        emit(DealStatsErrorManager(message: 'Нет подключения к интернету и данных в кеше.'));
      }
    } catch (e) {
      print("⚠️ Ошибка загрузки данных: $e");
      emit(DealStatsErrorManager(message: e.toString()));
    }
  }
}