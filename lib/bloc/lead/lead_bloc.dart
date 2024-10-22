import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'lead_event.dart';
import 'lead_state.dart';

class LeadBloc extends Bloc<LeadEvent, LeadState> {
  final ApiService apiService;

  LeadBloc(this.apiService) : super(LeadInitial()) {
    on<FetchLeadStatuses>(_fetchLeadStatuses);
    on<FetchLeads>(_fetchLeads);
    on<CreateLead>(_createLead);
  }

  Future<void> _fetchLeadStatuses(
      FetchLeadStatuses event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    await Future.delayed(Duration(milliseconds: 500)); // Небольшая задержка

    if (!await _checkInternetConnection()) {
      emit(LeadError('Нет подключения к интернету'));
      return;
    }

    try {
      final response = await apiService.getLeadStatuses();
      if (response.isEmpty) {
        emit(LeadError('Ответ пустой'));
        return;
      }
      emit(LeadLoaded(response));
    } catch (e) {
      emit(LeadError('Не удалось загрузить данные: ${e.toString()}'));
    }
  }

  Future<void> _fetchLeads(FetchLeads event, Emitter<LeadState> emit) async {
    emit(LeadLoading());
    if (!await _checkInternetConnection()) {
      emit(LeadError('Нет подключения к интернету'));
      return;
    }

    try {
      final leads = await apiService.getLeads(event.statusId);
      emit(LeadDataLoaded(leads));
    } catch (e) {
      emit(LeadError('Не удалось загрузить лиды: ${e.toString()}'));
    }
  }

  Future<void> _createLead(CreateLead event, Emitter<LeadState> emit) async {
    emit(LeadLoading());

    // Проверка подключения к интернету
    if (!await _checkInternetConnection()) {
      emit(LeadError('Нет подключения к интернету'));
      return;
    }

    try {
      // Вызов метода создания лида
      final result = await apiService.createLead(
        name: event.name,
        leadStatusId: event.leadStatusId,
        phone: event.phone,
        regionId: event.regionId,
        instaLogin: event.instaLogin,
        facebookLogin: event.facebookLogin,
        tgNick: event.tgNick,
        birthday: event.birthday,
        description: event.description,
        organizationId: event.organizationId,
        waPhone: event.waPhone,
      );

      // Если успешно, то обновляем состояние
      if (result['success']) {
        emit(LeadSuccess('Лид создан успешно'));
        // Передаем статус лида (event.leadStatusId) в событие FetchLeads
        add(FetchLeads(event.leadStatusId));
      } else {
        // Если есть ошибка, отображаем сообщение об ошибке
        emit(LeadError(result['message']));
      }
    } catch (e) {
      // Логирование ошибки
      emit(LeadError('Ошибка создания лида: ${e.toString()}'));
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
