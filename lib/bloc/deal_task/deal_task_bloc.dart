import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal_task/deal_task_event.dart';
import 'package:crm_task_manager/bloc/deal_task/deal_task_state.dart';

class DealTasksBloc extends Bloc<DealTasksEvent, DealTasksState> {
  final ApiService apiService;
  bool allDealTasksFetched = false;

  DealTasksBloc(this.apiService) : super(DealTasksInitial()) {
    on<FetchDealTasks>(_fetchDealTasks);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _fetchDealTasks(FetchDealTasks event, Emitter<DealTasksState> emit) async {
    emit(DealTasksLoading());

    if (await _checkInternetConnection()) {
      try {
        final tasks = await apiService.getDealTasks(event.taskId);
        allDealTasksFetched = tasks.isEmpty;
        emit(DealTasksLoaded(tasks));
      } catch (e) {
        emit(DealTasksError('Не удалось загрузить сделки задачи!'));
      }
    } else {
      emit(DealTasksError('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
    }
  }
}
