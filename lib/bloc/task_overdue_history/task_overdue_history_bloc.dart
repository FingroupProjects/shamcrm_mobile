import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task_overdue_history/task_overdue_history_event.dart';
import 'package:crm_task_manager/bloc/task_overdue_history/task_overdue_history_state.dart';
import 'package:flutter/foundation.dart';

class TaskOverdueHistoryBloc extends Bloc<TaskOverdueHistoryEvent, TaskOverdueHistoryState> {
  final ApiService apiService;

  TaskOverdueHistoryBloc(this.apiService) : super(TaskOverdueHistoryInitial()) {
    on<FetchTaskOverdueHistory>(_onFetchTaskOverdueHistory);
  }

  Future<void> _onFetchTaskOverdueHistory(
    FetchTaskOverdueHistory event,
    Emitter<TaskOverdueHistoryState> emit,
  ) async {
    emit(TaskOverdueHistoryLoading());
    try {
      if (kDebugMode) {
        debugPrint('TaskOverdueHistoryBloc: Fetching history for task ${event.taskId}');
      }

      final response = await apiService.getTaskOverdueHistory(event.taskId);

      if (response?.result != null && response!.result!.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('TaskOverdueHistoryBloc: Loaded ${response.result!.length} history items');
        }
        emit(TaskOverdueHistoryLoaded(response.result!));
      } else {
        if (kDebugMode) {
          debugPrint('TaskOverdueHistoryBloc: No history data received');
        }
        emit(const TaskOverdueHistoryError('Не удалось загрузить историю выполнения'));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TaskOverdueHistoryBloc: Error loading history: $e');
      }
      emit(const TaskOverdueHistoryError('Ошибка загрузки истории выполнения'));
    }
  }
}
