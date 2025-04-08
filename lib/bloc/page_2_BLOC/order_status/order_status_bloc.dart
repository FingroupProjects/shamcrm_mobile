import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final ApiService apiService;

  OrderBloc(this.apiService) : super(OrderInitial()) {
    on<FetchOrderStatuses>(_fetchOrderStatuses);
    on<FetchOrders>(_fetchOrders);
    on<FetchOrderDetails>(_fetchOrderDetails);
    on<CreateOrder>(_createOrder);
    on<UpdateOrder>(_updateOrder);
    on<DeleteOrder>(_deleteOrder);
    on<ChangeOrderStatus>(_changeOrderStatus);
  }

  Future<void> _fetchOrderStatuses(FetchOrderStatuses event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final statuses = await apiService.getOrderStatuses();
      if (statuses.isEmpty) {
        emit(OrderError('Нет статусов заказов!'));
        return;
      }
      // Сохраняем текущее состояние, если оно есть
      if (state is OrderLoaded) {
        final currentState = state as OrderLoaded;
        emit(OrderLoaded(
          statuses,
          orders: currentState.orders,
          pagination: currentState.pagination,
          orderDetails: currentState.orderDetails,
        ));
      } else {
        emit(OrderLoaded(statuses));
      }
    } catch (e) {
      emit(OrderError('Не удалось загрузить статусы заказов: ${e.toString()}'));
    }
  }

  Future<void> _fetchOrders(FetchOrders event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final statuses = await apiService.getOrderStatuses();
      final orderResponse = await apiService.getOrders(
          statusId: event.statusId, page: event.page, perPage: event.perPage);
      emit(OrderLoaded(statuses,
          orders: orderResponse.data, pagination: orderResponse.pagination));
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

  Future<void> _createOrder(CreateOrder event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final success = await apiService.createOrder(
        phone: event.phone,
        leadId: event.leadId,
        delivery: event.delivery,
        deliveryAddress: event.deliveryAddress,
        goods: event.goods,
        organizationId: event.organizationId,
      );
      if (success) {
        emit(OrderSuccess());
      } else {
        emit(OrderError('Не удалось создать заказ'));
      }
    } catch (e) {
      emit(OrderError('Ошибка создания заказа: $e'));
    }
  }

  Future<void> _updateOrder(UpdateOrder event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final success = await apiService.updateOrder(
        orderId: event.orderId,
        phone: event.phone,
        leadId: event.leadId,
        delivery: event.delivery,
        deliveryAddress: event.deliveryAddress,
        goods: event.goods,
        organizationId: event.organizationId,
      );
      if (success) {
        final updatedOrder = await apiService.getOrderDetails(event.orderId);
        emit(OrderLoaded(await apiService.getOrderStatuses(),
            orderDetails: updatedOrder));
      } else {
        emit(OrderError('Не удалось обновить заказ'));
      }
    } catch (e) {
      emit(OrderError('Ошибка обновления заказа: $e'));
    }
  }

  Future<void> _deleteOrder(DeleteOrder event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final success = await apiService.deleteOrder(
        orderId: event.orderId,
        organizationId: event.organizationId,
      );
      if (success) {
        emit(OrderSuccess());
      } else {
        emit(OrderError('Не удалось удалить заказ'));
      }
    } catch (e) {
      emit(OrderError('Ошибка удаления заказа: $e'));
    }
  }

  Future<void> _changeOrderStatus(ChangeOrderStatus event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final success = await apiService.changeOrderStatus(
        orderId: event.orderId,
        statusId: event.statusId,
        organizationId: event.organizationId,
      );
      if (success) {
        final statuses = await apiService.getOrderStatuses();
        if (state is OrderLoaded) {
          final currentState = state as OrderLoaded;
          final updatedOrders = currentState.orders.map((order) {
            if (order.id == event.orderId) {
              return order.copyWith(
                orderStatus: OrderStatusName.fromOrderStatus(
                  statuses.firstWhere((status) => status.id == event.statusId),
                ),
              );
            }
            return order;
          }).toList();
          emit(OrderLoaded(statuses,
              orders: updatedOrders, pagination: currentState.pagination));
        } else {
          emit(OrderLoaded(statuses));
        }
      } else {
        emit(OrderError('Не удалось сменить статус заказа'));
      }
    } catch (e) {
      emit(OrderError('Ошибка смены статуса заказа: $e'));
    }
  }
}