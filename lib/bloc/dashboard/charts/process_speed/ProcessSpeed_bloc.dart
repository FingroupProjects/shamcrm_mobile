// Bloc
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/process_speed/ProcessSpeed_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProcessSpeedBloc extends Bloc<ProcessSpeedEvent, ProcessSpeedState> {
  final ApiService _apiService;

  ProcessSpeedBloc(this._apiService) : super(ProcessSpeedInitial()) {
    on<LoadProcessSpeedData>(_onLoadProcessSpeedData);
  }

  Future<void> _onLoadProcessSpeedData(
    LoadProcessSpeedData event,
    Emitter<ProcessSpeedState> emit,
  ) async {
    try {
      emit(ProcessSpeedLoading());
      final processSpeedData = await _apiService.getProcessSpeedData();
      emit(ProcessSpeedLoaded(processSpeedData: processSpeedData));
    } catch (e) {
      emit(ProcessSpeedError(message: e.toString()));
    }
  }
}