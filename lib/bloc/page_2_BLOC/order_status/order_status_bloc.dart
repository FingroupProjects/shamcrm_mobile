// bloc/order/order_bloc.dart
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final ApiService apiService;

  OrderBloc(this.apiService) : super(OrderInitial()) {
    on<FetchOrderStatuses>(_fetchOrderStatuses);
    on<FetchOrders>(_fetchOrders);
    on<FetchOrderDetails>(_fetchOrderDetails);
  }

  Future<void> _fetchOrderStatuses(FetchOrderStatuses event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final statuses = await apiService.getOrderStatuses();
      if (statuses.isEmpty) {
        emit(OrderError('Нет статусов заказов!'));
        return;
      }
      emit(OrderLoaded(statuses));
    } catch (e) {
      emit(OrderError('Не удалось загрузить статусы заказов: ${e.toString()}'));
    }
  }

  Future<void> _fetchOrders(FetchOrders event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final statuses = await apiService.getOrderStatuses();
      final orderResponse = await apiService.getOrders(
        statusId: event.statusId,
        page: event.page,
        perPage: event.perPage,
      );
      emit(OrderLoaded(statuses, orders: orderResponse.data, pagination: orderResponse.pagination));
    } catch (e) {
      emit(OrderError('Не удалось загрузить заказы: ${e.toString()}'));
    }
  }

  Future<void> _fetchOrderDetails(FetchOrderDetails event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final statuses = await apiService.getOrderStatuses();
      final orderDetails = await apiService.getOrderDetails(event.orderId);
      emit(OrderLoaded(statuses, orderDetails: orderDetails));
    } catch (e) {
      emit(OrderError('Не удалось загрузить детали заказа: ${e.toString()}'));
    }
  }
}