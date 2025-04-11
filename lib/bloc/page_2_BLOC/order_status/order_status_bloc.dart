import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final ApiService apiService;
  Map<int?, List<Order>> allOrders = {};
  Map<int?, bool> allOrdersFetched = {};

  OrderBloc(this.apiService) : super(OrderInitial()) {
    on<FetchOrderStatuses>(_fetchOrderStatuses);
    on<FetchOrders>(_fetchOrders);
    on<FetchMoreOrders>(_fetchMoreOrders);
    on<FetchOrderDetails>(_fetchOrderDetails);
    on<CreateOrder>(_createOrder);
    on<UpdateOrder>(_updateOrder);
    on<DeleteOrder>(_deleteOrder);
    on<ChangeOrderStatus>(_changeOrderStatus);
  }

  Future<void> _fetchOrderStatuses(
      FetchOrderStatuses event, Emitter<OrderState> emit) async {
    try {
      final statuses = await apiService.getOrderStatuses();
      if (statuses.isEmpty) {
        emit(OrderError('Нет статусов заказов!'));
        return;
      }
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
    print(
        'Fetching orders for statusId: ${event.statusId}, page: ${event.page}, forceRefresh: ${event.forceRefresh}');

    // Если forceRefresh включен, очищаем кэш для этого статуса
    if (event.forceRefresh) {
      allOrders[event.statusId] = [];
      allOrdersFetched[event.statusId] = false;
    }

    // Проверяем, можно ли использовать кэшированные данные
    if (!event.forceRefresh &&
        event.page == 1 &&
        (allOrders[event.statusId]?.isNotEmpty ?? false)) {
      emit(OrderLoaded(
        state is OrderLoaded ? (state as OrderLoaded).statuses : [],
        orders: allOrders[event.statusId]!,
        pagination:
            state is OrderLoaded ? (state as OrderLoaded).pagination : null,
      ));
      return;
    }

    if (event.page == 1) {
      emit(OrderLoading());
    }

    try {
      final statuses = state is OrderLoaded
          ? (state as OrderLoaded).statuses
          : await apiService.getOrderStatuses();
      final orderResponse = await apiService.getOrders(
        statusId: event.statusId,
        page: event.page,
        perPage: event.perPage,
      );

      print('Received orders: ${orderResponse.data.length}');

      // Очищаем данные для первой страницы, если не было forceRefresh
      if (event.page == 1 && !event.forceRefresh) {
        allOrders[event.statusId] = [];
        allOrdersFetched[event.statusId] = false;
      }

      // Проверяем дубликаты
      final existingOrderIds =
          (allOrders[event.statusId] ?? []).map((order) => order.id).toSet();
      final newOrders = orderResponse.data
          .where((order) => !existingOrderIds.contains(order.id))
          .toList();

      allOrders[event.statusId] = (allOrders[event.statusId] ?? []) + newOrders;
      allOrdersFetched[event.statusId] =
          orderResponse.data.length < event.perPage;

      emit(OrderLoaded(
        statuses,
        orders: allOrders[event.statusId] ?? [],
        pagination: Pagination(
          currentPage: orderResponse.pagination.currentPage,
          totalPages: orderResponse.pagination.totalPages,
          total: orderResponse.pagination.total,
          count: orderResponse.pagination.count,
          perPage: orderResponse.pagination.perPage,
        ),
      ));
    } catch (e) {
      emit(OrderError('Не удалось загрузить заказы: ${e.toString()}'));
    }
  }

  Future<void> _fetchMoreOrders(
      FetchMoreOrders event, Emitter<OrderState> emit) async {
    if (allOrdersFetched[event.statusId] == true || state is! OrderLoaded)
      return;

    print(
        'Fetching more orders for statusId: ${event.statusId}, page: ${event.page}');

    try {
      final orderResponse = await apiService.getOrders(
        statusId: event.statusId,
        page: event.page,
        perPage: event.perPage,
      );

      final existingOrderIds =
          (allOrders[event.statusId] ?? []).map((order) => order.id).toSet();
      final newOrders = orderResponse.data
          .where((order) => !existingOrderIds.contains(order.id))
          .toList();

      allOrders[event.statusId] = (allOrders[event.statusId] ?? []) + newOrders;
      allOrdersFetched[event.statusId] =
          orderResponse.data.length < event.perPage || newOrders.isEmpty;

      print(
          'Loaded more orders: ${newOrders.length}, total: ${allOrders[event.statusId]?.length}, fetched: ${allOrdersFetched[event.statusId]}');

      final currentState = state as OrderLoaded;
      emit(OrderLoaded(
        currentState.statuses,
        orders: allOrders[event.statusId] ?? [],
        pagination: Pagination(
          currentPage: orderResponse.pagination.currentPage,
          totalPages: orderResponse.pagination.totalPages,
          total: orderResponse.pagination.total,
          count: orderResponse.pagination.count,
          perPage: orderResponse.pagination.perPage,
        ),
      ));
    } catch (e) {
      emit(OrderError(
          'Не удалось загрузить дополнительные заказы: ${e.toString()}'));
    }
  }

  Future<void> _fetchOrderDetails(
      FetchOrderDetails event, Emitter<OrderState> emit) async {
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
      final result = await apiService.createOrder(
        phone: event.phone,
        leadId: event.leadId,
        delivery: event.delivery,
        deliveryAddress: event.deliveryAddress,
        goods: event.goods,
        organizationId: event.organizationId,
      );
      if (result['success']) {
        emit(OrderSuccess(statusId: result['statusId'] ?? 1));
      } else {
        emit(OrderError('Не удалось создать заказ: ${result['error']}'));
      }
    } catch (e) {
      emit(OrderError('Ошибка создания заказа: $e'));
    }
  }

  Future<void> _updateOrder(UpdateOrder event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final response = await apiService.updateOrder(
        orderId: event.orderId,
        phone: event.phone,
        leadId: event.leadId,
        delivery: event.delivery,
        deliveryAddress: event.deliveryAddress,
        goods: event.goods,
        organizationId: event.organizationId,
      );

      if (response == true) {
        emit(OrderSuccess());
      } else {
        emit(OrderError('Не удалось обновить заказ'));
      }
    } catch (e) {
      emit(OrderError('Ошибка при обновлении заказа: ${e.toString()}'));
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

  Future<void> _changeOrderStatus(
      ChangeOrderStatus event, Emitter<OrderState> emit) async {
    try {
      final success = await apiService.changeOrderStatus(
        orderId: event.orderId,
        statusId: event.statusId,
        organizationId: event.organizationId,
      );
      print('Результат смены статуса: $success');
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
          emit(OrderLoaded(
            statuses,
            orders: updatedOrders,
            pagination: currentState.pagination,
          ));
        } else {
          emit(OrderLoaded(statuses));
        }
      } else {
        emit(OrderError(
            'Не удалось сменить статус заказа: сервер вернул ошибку'));
      }
    } catch (e) {
      print('Детали ошибки смены статуса: $e');
      emit(OrderError('Ошибка смены статуса заказа: $e'));
    }
  }
}
