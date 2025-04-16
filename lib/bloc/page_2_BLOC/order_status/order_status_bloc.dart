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
  if (event.page == 1) {
    emit(OrderLoading());
  }

  try {
    final statuses = await apiService.getOrderStatuses();
    final orderResponse = await apiService.getOrders(
      statusId: event.statusId,
      page: event.page,
      perPage: event.perPage,
    );

    // Очищаем данные для первой страницы
    if (event.page == 1) {
      allOrders[event.statusId] = [];
      allOrdersFetched[event.statusId] = false;
    }

    // Проверяем на дубликаты
    final existingOrderIds = (allOrders[event.statusId] ?? []).map((order) => order.id).toSet();
    final newOrders = orderResponse.data.where((order) => !existingOrderIds.contains(order.id)).toList();

    // Обновляем список заказов
    allOrders[event.statusId] = (allOrders[event.statusId] ?? []) + newOrders;
    allOrdersFetched[event.statusId] = newOrders.length < event.perPage || newOrders.isEmpty;

    // print('Fetched orders: statusId=${event.statusId}, page=${event.page}, newOrders=${newOrders.length}, hasMore=${!allOrdersFetched[event.statusId]}');

    emit(OrderLoaded(
      statuses,
      orders: allOrders[event.statusId] ?? [],
      pagination: orderResponse.pagination,
    ));
  } catch (e) {
    emit(OrderError('Не удалось загрузить заказы: ${e.toString()}'));
  }
}
Future<void> _fetchMoreOrders(FetchMoreOrders event, Emitter<OrderState> emit) async {
  if (allOrdersFetched[event.statusId] == true || state is! OrderLoaded) return;

  try {
    final orderResponse = await apiService.getOrders(
      statusId: event.statusId,
      page: event.page,
      perPage: event.perPage,
    );

    // Проверяем, не дублируются ли заказы
    final existingOrderIds = (allOrders[event.statusId] ?? []).map((order) => order.id).toSet();
    final newOrders = orderResponse.data.where((order) => !existingOrderIds.contains(order.id)).toList();

    // Обновляем список заказов
    allOrders[event.statusId] = (allOrders[event.statusId] ?? []) + newOrders;
    allOrdersFetched[event.statusId] = newOrders.length < event.perPage || newOrders.isEmpty;

    // print('Fetched more orders: statusId=${event.statusId}, page=${event.page}, newOrders=${newOrders.length}, hasMore=${!allOrdersFetched[event.statusId]}');

    final currentState = state as OrderLoaded;
    emit(OrderLoaded(
      currentState.statuses,
      orders: allOrders[event.statusId] ?? [],
      pagination: orderResponse.pagination,
    ));
  } catch (e) {
    emit(OrderError('Не удалось загрузить дополнительные заказы: ${e.toString()}'));
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
      statusId: event.statusId,
    );
    
    if (result['success']) {
      final statusId = result['statusId'] ?? event.statusId;
      final orderData = result['order'];

      // Создаем новый Order из полученных данных
      final newOrder = Order.fromJson(orderData);
      
      // Добавляем новый заказ в соответствующий статус
      if (allOrders[statusId] == null) {
        allOrders[statusId] = [];
      }
      allOrders[statusId]!.insert(0, newOrder); // Добавляем в начало списка

      // Получаем актуальные статусы
      final statuses = await apiService.getOrderStatuses();

      // Обновляем состояние
      emit(OrderLoaded(
        statuses,
        orders: allOrders[statusId] ?? [],
        pagination: Pagination(
          total: (allOrders[statusId]?.length ?? 0) + 1,
          count: allOrders[statusId]?.length ?? 0,
          perPage: 20,
          currentPage: 1,
          totalPages: 1,
        ),
      ));

      // Уведомляем о успешном создании
      emit(OrderSuccess(statusId: statusId));
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
