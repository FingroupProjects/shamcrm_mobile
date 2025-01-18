import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/process_speed/ProcessSpeed_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/process_speed/ProcessSpeed_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models_manager/process_speed%20_model.dart';
import 'package:crm_task_manager/screens/dashboard_for_manager/CACHE/process_speed_manager_cache.dart';
import 'package:flutter/material.dart';
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
      debugPrint("🕐 Начата загрузка данных...");
      emit(ProcessSpeedLoadingManager());

      // 1. Показываем данные из кэша (если они есть)
      debugPrint("📂 Проверка кэша...");
      final cachedSpeed = await ProcessSpeedCacheManager.getProcessSpeedDataManager();
      if (cachedSpeed != null) {
        debugPrint("📦 Найдены данные в кеше ProcessSpeed: $cachedSpeed");
        emit(ProcessSpeedLoadedManager(processSpeedData: ProcessSpeedManager(speed: cachedSpeed)));
      } else {
        debugPrint("⚠️ Кэш пуст.");
      }

      // 2. Асинхронно проверяем сервер
      debugPrint("🌐 Проверка интернет-соединения...");
      if (await _checkInternetConnection()) {
        debugPrint("📡 Интернет-соединение установлено. Загружаем данные с сервера...");
        final processSpeedData = await _apiService.getProcessSpeedDataManager();

        // Сравниваем данные и обновляем кэш, если необходимо
        if (cachedSpeed == null || cachedSpeed != processSpeedData.speed) {
          debugPrint("💾 Обновление кэша с новыми данными: ${processSpeedData.speed}");
          await ProcessSpeedCacheManager.saveProcessSpeedDataManager(processSpeedData.speed);
          emit(ProcessSpeedLoadedManager(processSpeedData: processSpeedData));
        } else {
          debugPrint("🔄 СКОРОСТЬ ОБРАБОТКИ Данные из кэша совпадают с сервером.");
          emit(ProcessSpeedLoadedManager(processSpeedData: ProcessSpeedManager(speed: cachedSpeed)));
        }
      } else if (cachedSpeed == null) {
        debugPrint("❌ Интернет отсутствует и данные из кэша не найдены.");
        emit(ProcessSpeedErrorManager(message: "Нет данных и отсутствует подключение к интернету."));
      }
    } catch (e) {
      debugPrint("❗ Ошибка: $e");
      emit(ProcessSpeedErrorManager(message: "Ошибка загрузки данных графика Скорость обработки"));
    }
  }
}
