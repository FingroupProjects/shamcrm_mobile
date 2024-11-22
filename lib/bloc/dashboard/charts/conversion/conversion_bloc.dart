import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/conversion/conversion_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class DashboardConversionBloc
    extends Bloc<DashboardConversionEvent, DashboardConversionState> {
  final ApiService _apiService;

  DashboardConversionBloc(this._apiService)
      : super(DashboardConversionInitial()) {
    on<LoadLeadConversionData>(_onLoadLeadConversionData);
  }

  Future<void> _onLoadLeadConversionData(
    LoadLeadConversionData event,
    Emitter<DashboardConversionState> emit,
  ) async {
    try {
      emit(DashboardConversionLoading());
      final leadConversionData = await _apiService.getLeadConversionData();
      emit(DashboardConversionLoaded(leadConversionData: leadConversionData));
    } catch (e) {
      emit(DashboardConversionError(message: e.toString()));
    }
  }
}
