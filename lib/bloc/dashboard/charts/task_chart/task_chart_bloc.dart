
import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/task_chart/task_chart_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/task_chart_model.dart';
import 'package:crm_task_manager/screens/dashboard/CACHE/task_chart_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardTaskChartBloc
    extends Bloc<DashboardTaskChartEvent, DashboardTaskChartState> {
  final ApiService _apiService;

  DashboardTaskChartBloc(this._apiService)
      : super(DashboardTaskChartInitial()) {
    on<LoadTaskChartData>(_onLoadTaskChartData);
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

  // Сравнение двух списков данных
  bool _areListsEqual(List<double> a, List<double> b) {
    if (a.length != b.length) return false; // Сравниваем длину списков
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false; // Сравниваем элементы на каждой позиции
    }
    return true;
  }

  Future<void> _onLoadTaskChartData(
    LoadTaskChartData event,
    Emitter<DashboardTaskChartState> emit,
  ) async {
    try {
      print("🚀 Загрузка данных о графике задач...");
      emit(DashboardTaskChartLoading());

      // 1. Показываем данные из кэша (если они есть)
      List<double>? cachedData = await TaskChartCacheHandler.getTaskChartData();
      if (cachedData != null) {
        print("📦 Найдены данные в кеше.");
        emit(DashboardTaskChartLoaded(taskChartData: TaskChart(data: cachedData)));
      }

      // 2. Асинхронно проверяем сервер
      if (await _checkInternetConnection()) {
        print("🌐 Интернет подключен. Получаем данные с сервера...");

        final taskChartData = await _apiService.getTaskChartData();

        // Если данные с сервера не совпадают с кэшированными, обновляем кэш и UI
        if (cachedData == null || !_areListsEqual(taskChartData.data, cachedData)) {
          print("✅ ЗАДАЧИ Данные с сервера отличаются. Обновляем кэш и UI.");

          // Сохраняем новые данные в кэш
          await TaskChartCacheHandler.saveTaskChartData(taskChartData.data);

          // Обновляем UI
          emit(DashboardTaskChartLoaded(taskChartData: taskChartData));
        } else {
          print("🔄 ЗАДАЧИ Данные с сервера совпадают с кешированными. Обновление не требуется.");
        }
      } else {
        print("🚫 Нет подключения к интернету.");
        if (cachedData == null) {
          emit(DashboardTaskChartError(message: "Нет данных и отсутствует подключение к интернету."));
        }
      }
    } catch (e) {
      print("❌ Произошла ошибка: $e");
      emit(DashboardTaskChartError(message: e.toString()));
    }
  }
}
