import 'dart:io';
import 'package:crm_task_manager/bloc/dashboard/stats_event.dart';
import 'package:crm_task_manager/bloc/dashboard/stats_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class DashboardStatsBloc extends Bloc<DashboardStatsEvent, DashboardStatsState> {
  final ApiService _apiService;

  DashboardStatsBloc(this._apiService) : super(DashboardStatsInitial()) {
    on<LoadDashboardStats>(_onLoadDashboardStats);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<DashboardStatsState> emit,
  ) async {
    try {
      emit(DashboardStatsLoading());
      
      // Check if there is an internet connection
      if (await _checkInternetConnection()) {
        final stats = await _apiService.getDashboardStats();
        emit(DashboardStatsLoaded(stats: stats));
      } else {
        // emit(DashboardStatsError(message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
      }
    } catch (e) {
      emit(DashboardStatsError(message: e.toString()));
    }
  }
}
