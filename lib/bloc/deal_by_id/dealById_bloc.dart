import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_event.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealByIdBloc extends Bloc<DealByIdEvent, DealByIdState> {
  final ApiService apiService;

  DealByIdBloc(this.apiService) : super(DealByIdInitial()) {
    on<FetchDealByIdEvent>(_getDealById);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _getDealById(FetchDealByIdEvent event, Emitter<DealByIdState> emit) async {
    emit(DealByIdLoading());

    if (await _checkInternetConnection()) {
      try {
        final deal = await apiService.getDealById(event.dealId);
        emit(DealByIdLoaded(deal));
      } catch (e) {
        emit(DealByIdError('Не удалось загрузить данные сделки: ${e.toString()}'));
      }
    } else {
      emit(DealByIdError('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
    }
  }
}
