import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_state.dart';
import 'package:crm_task_manager/models/dashboard_charts_models/user_task%20_model.dart';
import 'package:crm_task_manager/screens/dashboard/CACHE/users_chart_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskCompletionBloc extends Bloc<TaskCompletionEvent, TaskCompletionState> {
  final ApiService apiService;

  TaskCompletionBloc(this.apiService) : super(TaskCompletionInitial()) {
    on<LoadTaskCompletionData>(_onLoadTaskCompletionData);
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

  Future<void> _onLoadTaskCompletionData(
    LoadTaskCompletionData event,
    Emitter<TaskCompletionState> emit,
  ) async {
    try {
      emit(TaskCompletionLoading());

      // 1. Показываем данные из кэша (если они есть)
      List<UserTaskCompletion>? cachedData = await TaskCompletionCache.getTaskCompletionData();

      if (cachedData != null) {
        print("📦 Найдены данные в кеше: ${cachedData.length} пользователей.");
        emit(TaskCompletionLoaded(data: cachedData));
      }

      // 2. Асинхронно проверяем сервер
      if (await _checkInternetConnection()) {
        print("🌐 Интернет подключен. Получаем данные с сервера...");

        final data = await apiService.getUsersChartData();

        // Если данные из кэша отличаются от полученных данных
        if (cachedData == null || !_areListsEqual(data, cachedData)) {
          print("✅ Новые данные с сервера отличаются. Обновляем кэш и UI.");

          // Сохраняем новые данные в кэш
          await TaskCompletionCache.saveTaskCompletionData(data);

          // Обновляем UI
          emit(TaskCompletionLoaded(data: data));
        } else {
          print("🔄 ВЫПОЛНЕНИЕ ЦЕЛЕЙ Данные с сервера совпадают с кешированными. Обновление не требуется.");
        }
      } else {
        print("🚫 Нет подключения к интернету.");
        if (cachedData == null) {
          emit(TaskCompletionError(message: "Нет данных и отсутствует подключение к интернету."));
        }
      }
    } catch (e) {
      print("❌ Произошла ошибка: $e");
      emit(TaskCompletionError(message: e.toString()));
    }
  }

  // Сравнение списков
  bool _areListsEqual(List<UserTaskCompletion> a, List<UserTaskCompletion> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name || a[i].finishedTasksprocent != b[i].finishedTasksprocent) {
        return false;
      }
    }
    return true;
  }
}
