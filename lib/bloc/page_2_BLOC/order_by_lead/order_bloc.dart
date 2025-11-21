import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class OrderByLeadBloc extends Bloc<OrderByLeadEvent, OrderByLeadState> {
  final ApiService apiService;

  OrderByLeadBloc(this.apiService) : super(OrderByLeadInitial()) {
    on<FetchOrdersByLead>(_onFetchOrdersByLead);
  }

  Future<void> _onFetchOrdersByLead(
    FetchOrdersByLead event,
    Emitter<OrderByLeadState> emit,
  ) async {
    emit(OrderByLeadLoading());
    try {
      final orderResponse = await apiService.getOrdersByLead(
        leadId: event.leadId,
        page: event.page,
        perPage: event.perPage,
      );
      emit(OrderByLeadLoaded(
        orders: orderResponse.data,
        pagination: orderResponse.pagination,
      ));
    } catch (e) {
      emit(OrderByLeadError('Ошибка загрузки заказов: $e'));
    }
  }
}