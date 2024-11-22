import 'package:crm_task_manager/bloc/dashboard/stats_event.dart';
import 'package:crm_task_manager/bloc/dashboard/stats_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';


class DashboardStatsBloc extends Bloc<DashboardStatsEvent, DashboardStatsState> {
  final ApiService _apiService;

  DashboardStatsBloc(this._apiService) : super(DashboardStatsInitial()) {
    on<LoadDashboardStats>(_onLoadDashboardStats);
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<DashboardStatsState> emit,
  ) async {
    try {
      emit(DashboardStatsLoading());
      final stats = await _apiService.getDashboardStats();
      emit(DashboardStatsLoaded(stats: stats));
    } catch (e) {
      emit(DashboardStatsError(message: e.toString()));
    }
  }
}
