import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_status_for_filter/lead_status_for_filter_event.dart';
import 'package:crm_task_manager/bloc/lead_status_for_filter/lead_status_for_filter_state.dart';

class LeadStatusForFilterBloc extends Bloc<LeadStatusForFilterEvent, LeadStatusForFilterState> {
  final ApiService apiService;
  bool allLeadStatusForFilterFetched = false;

  LeadStatusForFilterBloc(this.apiService) : super(LeadStatusForFilterInitial()) {
    on<FetchLeadStatusForFilter>(_fetchLeadStatusForFilter);
  }

  Future<void> _fetchLeadStatusForFilter(
      FetchLeadStatusForFilter event, Emitter<LeadStatusForFilterState> emit) async {
    emit(LeadStatusForFilterLoading());

    if (await _checkInternetConnection()) {
      try {
        final leadStatusForFilter = await apiService.getLeadStatusForFilter();
        allLeadStatusForFilterFetched = leadStatusForFilter.isEmpty;
        emit(LeadStatusForFilterLoaded(leadStatusForFilter));
      } catch (e) {
        emit(LeadStatusForFilterError('Не удалось загрузить список статусов лидов!'));
      }
    } else {
      emit(LeadStatusForFilterError('Нет подключения к интернету'));
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      return false;
    }
  }
}