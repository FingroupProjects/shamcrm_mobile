import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'deal_history_event.dart';
import 'deal_history_state.dart';

class DealHistoryBloc extends Bloc<DealHistoryEvent, DealHistoryState> {
  final ApiService apiService;

  DealHistoryBloc(this.apiService) : super(DealHistoryInitial()) {
    on<FetchDealHistory>((event, emit) async {
      emit(DealHistoryLoading());

      if (await _checkInternetConnection()) {
        try {
          final dealHistory = await apiService.getDealHistory(event.dealId);
          emit(DealHistoryLoaded(dealHistory));
        } catch (e) {
          emit(DealHistoryError('Ошибка при загрузке истории сделки: ${e.toString()}'));
        }
      } else {
        emit(DealHistoryError('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
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
