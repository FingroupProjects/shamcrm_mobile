// bloc/dashboard/dashboard_bloc.dart
import 'package:crm_task_manager/bloc/dashboard/dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/dashboard_event.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ApiService _apiService;

  DashboardBloc(this._apiService) : super(DashboardInitial()) {
    on<LoadDashboardStats>(_onLoadDashboardStats);
    on<LoadLeadConversionData>(_onLoadLeadConversionData);
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      emit(DashboardLoading());

      final stats = await _apiService.getDashboardStats();
      final chartData = await _apiService.getLeadChart();

      emit(DashboardLoaded(
        stats: stats,
        chartData: chartData,
      ));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }

  // Метод для загрузки LeadConversionData
  Future<void> _onLoadLeadConversionData(
    LoadLeadConversionData event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      emit(DashboardLoading());
      final leadConversionData = await _apiService.getLeadConversionData();
      emit(LeadConversionDataLoaded(leadConversionData: leadConversionData));
    } catch (e) {
      emit(DashboardError(message: e.toString()));
    }
  }
}
