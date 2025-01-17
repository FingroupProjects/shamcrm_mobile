import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/lead_conversion_model.dart';
import 'package:crm_task_manager/screens/dashboard/CACHE/lead_conversion_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardConversionBloc
    extends Bloc<DashboardConversionEvent, DashboardConversionState> {
  final ApiService _apiService;

  DashboardConversionBloc(this._apiService)
      : super(DashboardConversionInitial()) {
    on<LoadLeadConversionData>(_onLoadLeadConversionData);
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
  LoadLeadConversionData event,
  Emitter<DashboardConversionState> emit,
) async {
  try {
    print("🚀 Загрузка данных о конверсии лидов...");
    emit(DashboardConversionLoading());

    // 1. Показываем данные из кэша (если они есть)
    List<double>? cachedData = await CacheHandler.getLeadConversionData();

    if (cachedData != null) {
      print("📦 Найдены данные в кеше: ${cachedData.length} месяцев.");
      emit(DashboardConversionLoaded(
        leadConversionData: LeadConversion(monthlyData: cachedData),
      ));
    }

    // 2. Асинхронно проверяем сервер
    if (await _checkInternetConnection()) {
      print("🌐 Интернет подключен. Получаем данные с сервера...");

      final leadConversionData = await _apiService.getLeadConversionData();

      if (cachedData == null || 
          !_areListsEqual(leadConversionData.monthlyData, cachedData)) {
        print("✅ Новые данные с сервера отличаются. Обновляем кэш и UI.");

        // Сохраняем новые данные в кэш
        await CacheHandler.saveLeadConversionData(leadConversionData.monthlyData);

        // Обновляем UI
        emit(DashboardConversionLoaded(leadConversionData: leadConversionData));
      } else {
        print("🔄 КОНВЕРСИЯ Данные с сервера совпадают с кешированными. Обновление не требуется.");
      }
    } else {
      print("🚫 Нет подключения к интернету.");
      if (cachedData == null) {
        emit(DashboardConversionError(
          message: "Нет данных и отсутствует подключение к интернету.",
        ));
      }
    }
  } catch (e) {
    print("❌ Произошла ошибка: $e");
    emit(DashboardConversionError(message: e.toString()));
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