import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_event.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadByIdBloc extends Bloc<LeadByIdEvent, LeadByIdState> {
  final ApiService apiService;

  LeadByIdBloc(this.apiService) : super(LeadByIdInitial()) {
    on<FetchLeadByIdEvent>(_getLeadById);
  }

  Future<void> _getLeadById(FetchLeadByIdEvent event, Emitter<LeadByIdState> emit) async {
    emit(LeadByIdLoading());

    if (await _checkInternetConnection()) {
      try {
        final lead = await apiService.getLeadById(event.leadId);
        emit(LeadByIdLoaded(lead));
      } catch (e) {
        emit(LeadByIdError('Не удалось загрузить данные лида!'));
      }
    } else {
      emit(LeadByIdError('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
    }
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
