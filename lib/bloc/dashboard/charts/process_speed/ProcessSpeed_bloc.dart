import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/process_speed%20_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:crm_task_manager/screens/dashboard/CACHE/process_speed_cache.dart';

class ProcessSpeedBloc extends Bloc<ProcessSpeedEvent, ProcessSpeedState> {
  final ApiService _apiService;

  ProcessSpeedBloc(this._apiService) : super(ProcessSpeedInitial()) {
    on<LoadProcessSpeedData>(_onLoadProcessSpeedData);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _onLoadProcessSpeedData(
    LoadProcessSpeedData event,
    Emitter<ProcessSpeedState> emit,
  ) async {
    try {
      debugPrint("🕐 Начата загрузка данных...");
      emit(ProcessSpeedLoading());

      // 1. Показываем данные из кэша (если они есть)
      debugPrint("📂 Проверка кэша...");
      final cachedSpeed = await ProcessSpeedCache.getProcessSpeedData();
      if (cachedSpeed != null) {
        debugPrint("📦 Найдены данные в кеше ProcceSpeed: $cachedSpeed");
        emit(ProcessSpeedLoaded(processSpeedData: ProcessSpeed(speed: cachedSpeed)));
      } else {
        debugPrint("⚠️ Кэш пуст.");
      }

      // 2. Асинхронно проверяем сервер
      debugPrint("🌐 Проверка интернет-соединения...");
      if (await _checkInternetConnection()) {
        debugPrint("📡 Интернет-соединение установлено. Загружаем данные с сервера...");
        final processSpeedData = await _apiService.getProcessSpeedData();

        // Сравниваем данные и обновляем кэш, если необходимо
        if (cachedSpeed == null || cachedSpeed != processSpeedData.speed) {
          debugPrint("💾 Обновление кэша с новыми данными: ${processSpeedData.speed}");
          await ProcessSpeedCache.saveProcessSpeedData(processSpeedData.speed);
          emit(ProcessSpeedLoaded(processSpeedData: processSpeedData));
        } else {
          debugPrint("🔄 СКОРОСТЬ ОБРАБОТКИ Admin Данные из кэша совпадают с сервером.");
          emit(ProcessSpeedLoaded(processSpeedData: ProcessSpeed(speed: cachedSpeed)));
        }
      } else if (cachedSpeed == null) {
        debugPrint("❌ Интернет отсутствует и данные из кэша не найдены.");
        emit(ProcessSpeedError(message: "Нет данных и отсутствует подключение к интернету."));
      }
    } catch (e) {
      debugPrint("❗ Ошибка: $e");
      emit(ProcessSpeedError(message: "Ошибка загрузки данных графика Скорость обработки"));
    }
  }
}
