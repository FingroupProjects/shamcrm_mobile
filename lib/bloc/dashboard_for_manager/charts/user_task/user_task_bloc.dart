// Bloc
import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/user_task/user_task_event.dart';
import 'package:crm_task_manager/bloc/dashboard_for_manager/charts/user_task/user_task_state.dart';
import 'package:crm_task_manager/screens/dashboard_for_manager/CACHE/users_chart_manager_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserBlocManager extends Bloc<UserEvent, UserState> {
  final ApiService apiService;

  UserBlocManager(this.apiService) : super(UserInitial()) {
    on<LoadUserData>(_onLoadUserData);
  }

  Future<void> _onLoadUserData(
    LoadUserData event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(UserLoading());

      // 1. Попытка загрузить данные из кэша
      List<double>? cachedData = await UserTaskCompletionCacheHandler.getUserTaskCompletionData();

      if (cachedData != null) {
        emit(UserLoaded(data: cachedData));
      }

      // 2. Проверка подключения к интернету и загрузка данных с сервера, если это необходимо
      bool isInternetAvailable = await _checkInternetConnection();

      if (isInternetAvailable) {
        final data = await apiService.getUserStatsManager();
        if (cachedData == null || !_areListsEqual(data.finishedTasksPercent, cachedData)) {
          
          // Сохраняем новые данные в кэше
          await UserTaskCompletionCacheHandler.saveUserTaskCompletionData(data.finishedTasksPercent);
          
          // Обновляем UI с новыми данными
          emit(UserLoaded(data: data.finishedTasksPercent));
        } else {
        }
      } else {
        if (cachedData == null) {
          emit(UserError(message: "Нет данных и отсутствует подключение к интернету."));
        }
      }
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  // Проверка наличия подключения к интернету
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  // Проверка равенства двух списков
  bool _areListsEqual(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
