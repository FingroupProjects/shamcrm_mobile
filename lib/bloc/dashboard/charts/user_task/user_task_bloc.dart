// Bloc
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskCompletionBloc extends Bloc<TaskCompletionEvent, TaskCompletionState> {
  final ApiService apiService;

  TaskCompletionBloc(this.apiService) : super(TaskCompletionInitial()) {
    on<LoadTaskCompletionData>(_onLoadTaskCompletionData);
  }

  Future<void> _onLoadTaskCompletionData(
    LoadTaskCompletionData event,
    Emitter<TaskCompletionState> emit,
  ) async {
    try {
      emit(TaskCompletionLoading());
      
      final data = await apiService.getUsersChartData();
      emit(TaskCompletionLoaded(data: data));
      
    } catch (e) {
      emit(TaskCompletionError(message: e.toString()));
    }
  }
}