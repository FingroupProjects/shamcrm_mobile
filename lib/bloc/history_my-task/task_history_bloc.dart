import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'task_history_event.dart';
import 'task_history_state.dart';

class HistoryBlocMyTask extends Bloc<HistoryEvent, HistoryStateMyTask> {
  final ApiService apiService;

  HistoryBlocMyTask(this.apiService) : super(HistoryInitialMyTask()) {
    on<FetchMyTaskHistory>((event, emit) async {
      emit(HistoryLoadingMyTask());

      if (await _checkInternetConnection()) {
        try {
          final taskHistory = await apiService.getMyTaskHistory(event.taskId);
          emit(HistoryLoadedMyTask(taskHistory));
        } catch (e) {
          emit(HistoryErrorMyTask('Ошибка при загрузке истории задачи!'));
        }
      } else {
        emit(HistoryErrorMyTask('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
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
