import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'task_history_event.dart';
import 'task_history_state.dart';

class HistoryBlocTask extends Bloc<HistoryEvent, HistoryStateTask> {
  final ApiService apiService;

  HistoryBlocTask(this.apiService) : super(HistoryInitialTask()) {
    on<FetchTaskHistory>((event, emit) async {
      emit(HistoryLoadingTask());

      if (await _checkInternetConnection()) {
        try {
          final taskHistory = await apiService.getTaskHistory(event.taskId);
          emit(HistoryLoadedTask(taskHistory));
        } catch (e) {
          emit(HistoryErrorTask('Ошибка при загрузке истории задачи: ${e.toString()}'));
        }
      } else {
        emit(HistoryErrorTask('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
      }
    });
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}
