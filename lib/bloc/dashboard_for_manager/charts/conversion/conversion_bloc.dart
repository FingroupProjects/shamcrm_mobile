import 'dart:io';

import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/conversion/conversion_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/conversion/conversion_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/lead_conversion_model.dart';
import 'package:crm_task_manager/screens/dashboard_for_manager/CACHE/lead_conversion_manager_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class DashboardConversionBlocManager
    extends Bloc<DashboardConversionEventManager, DashboardConversionStateManager> {
  final ApiService _apiService;

  DashboardConversionBlocManager(this._apiService)
      : super(DashboardConversionInitialManager()) {
    on<LoadLeadConversionDataManager>(_onLoadLeadConversionData);
  }

  // Проверка подключения к интернету
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

      // 1. Показываем данные из кэша (если они есть)
      List<double>? cachedData = await CacheHandlerManager.getLeadConversionDataManager();

      if (cachedData != null) {
        emit(DashboardConversionLoadedManager(
          leadConversionData: LeadConversionManager(monthlyData: cachedData),
        ));
      }

      // 2. Асинхронно проверяем сервер
      if (await _checkInternetConnection()) {

        final leadConversionData = await _apiService.getLeadConversionDataManager();

        if (cachedData == null || !_areListsEqual(leadConversionData.monthlyData, cachedData)) {

          // Сохраняем новые данные в кэш
          await CacheHandlerManager.saveLeadConversionDataManager(leadConversionData.monthlyData);

          // Обновляем UI
          emit(DashboardConversionLoadedManager(leadConversionData: leadConversionData));
        } else {
        }
      } else {
        if (cachedData == null) {
          emit(DashboardConversionErrorManager(
            message: "Нет данных и отсутствует подключение к интернету.",
          ));
        }
      }
    } catch (e) {
      emit(DashboardConversionErrorManager(message: ""));
    }
  }

  // Сравнение списков
  bool _areListsEqual(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
