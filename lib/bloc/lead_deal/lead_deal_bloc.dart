import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_event.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_state.dart';

class LeadDealsBloc extends Bloc<LeadDealsEvent, LeadDealsState> {
  final ApiService apiService;
  bool allLeadDealsFetched = false;

  LeadDealsBloc(this.apiService) : super(LeadDealsInitial()) {
    on<FetchLeadDeals>(_fetchLeadDeals);
    on<FetchMoreLeadDeals>(_fetchMoreLeadDeals);
  }

  Future<void> _fetchLeadDeals(FetchLeadDeals event, Emitter<LeadDealsState> emit) async {
    emit(LeadDealsLoading());

    if (await _checkInternetConnection()) {
      try {
        final deals = await apiService.getLeadDeals(event.dealId);
        allLeadDealsFetched = deals.isEmpty;
        emit(LeadDealsLoaded(deals, currentPage: 1));
      } catch (e) {
        emit(LeadDealsError('Не удалось загрузить лида сделки: ${e.toString()}'));
      }
    } else {
      emit(LeadDealsError('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
    }
  }

  Future<void> _fetchMoreLeadDeals(FetchMoreLeadDeals event, Emitter<LeadDealsState> emit) async {
    if (allLeadDealsFetched) return;

    if (await _checkInternetConnection()) {
      try {
        final newDeals = await apiService.getLeadDeals(event.dealId, page: event.currentPage + 1);
        if (newDeals.isEmpty) {
          allLeadDealsFetched = true;
          return;
        }
        if (state is LeadDealsLoaded) {
          final currentState = state as LeadDealsLoaded;
          emit(currentState.merge(newDeals)); // Объединение с новыми сделками
        }
      } catch (e) {
        emit(LeadDealsError('Не удалось загрузить дополнительные сделки: ${e.toString()}'));
      }
    } else {
      emit(LeadDealsError('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
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
