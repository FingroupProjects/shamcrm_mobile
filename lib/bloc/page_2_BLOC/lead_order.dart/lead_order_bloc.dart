import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/lead_order.dart/lead_order_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/lead_order.dart/lead_order_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadOrderBloc extends Bloc<LeadOrderEvent, LeadOrderState> {
  final ApiService apiService;

  LeadOrderBloc(this.apiService) : super(LeadOrderInitial()) {
    on<FetchLeadOrders>(_onFetchLeadOrders);
  }

  Future<void> _onFetchLeadOrders(FetchLeadOrders event, Emitter<LeadOrderState> emit) async {
    try {
      emit(LeadOrderLoading());
      final leadOrders = await apiService.getLeadOrders();
      emit(LeadOrderLoaded(leadOrders: leadOrders));
    } catch (e) {
      emit(LeadOrderError(e.toString()));
    }
  }
}