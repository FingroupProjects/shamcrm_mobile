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

    try {
      final deals = await apiService.getLeadDeals(event.dealId); 
      allLeadDealsFetched = deals.isEmpty;
      emit(LeadDealsLoaded(deals, currentPage: 1)); 
    } catch (e) {
      emit(LeadDealsError('Не удалось загрузить лида сделки: ${e.toString()}'));
    }
  }

  Future<void> _fetchMoreLeadDeals(FetchMoreLeadDeals event, Emitter<LeadDealsState> emit) async {
    if (allLeadDealsFetched) return;

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
  }
}


