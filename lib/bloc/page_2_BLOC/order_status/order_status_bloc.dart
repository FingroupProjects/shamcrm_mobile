import 'dart:convert';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

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
    on<CreateOrderStatus>(_createOrderStatus);
    on<UpdateOrderStatus>(_updateOrderStatus);
    on<DeleteOrderStatus>(_deleteOrderStatus);
  }

  Future<void> _fetchOrderStatuses(FetchOrderStatuses event, Emitter<OrderState> emit) async {
    print('OrderBloc: Начало _fetchOrderStatuses');
    try {
      final statuses = await apiService.getOrderStatuses();
      print('OrderBloc: Получены статусы: ${statuses.map((s) => s.toJson()).toList()}');
      if (statuses.isEmpty) {
        print('OrderBloc: Статусы пусты, выдаем ошибку');
        emit(OrderError('Нет статусов заказов!'));
        return;
      }
      if (state is OrderLoaded) {
        final currentState = state as OrderLoaded;
        print('OrderBloc: Текущее состояние OrderLoaded, обновляем статусы');
        emit(OrderLoaded(
          statuses,
          orders: currentState.orders,
          pagination: currentState.pagination,
          orderDetails: currentState.orderDetails,
        ));
      } else {
        print('OrderBloc: Текущее состояние не OrderLoaded, создаем новое OrderLoaded');
        emit(OrderLoaded(statuses));
      }
    } catch (e) {
      if (state is! OrderStatusCreated) {
        print('OrderBloc: Ошибка при загрузке статусов: $e');
        emit(OrderError('Не удалось загрузить статусы заказов: ${e.toString()}'));
      }
    }
  }

  Future<void> _fetchOrders(FetchOrders event, Emitter<OrderState> emit) async {
    print('OrderBloc: Начало _fetchOrders для statusId=${event.statusId}, page=${event.page}, forceRefresh=${event.forceRefresh}');
    if (event.page == 1 && !event.forceRefresh) {
      print('OrderBloc: Загружаем первую страницу, устанавливаем OrderLoading');
      emit(OrderLoading());
    }

    try {
      final statuses = await apiService.getOrderStatuses();
      print('OrderBloc: Получены статусы для заказов: ${statuses.map((s) => s.toJson()).toList()}');
      final orderResponse = await apiService.getOrders(
        statusId: event.statusId,
        page: event.page,
        perPage: event.perPage,
      );
      print('OrderBloc: Получены заказы: ${orderResponse.data.map((o) => o.toJson()).toList()}');

      if (event.page == 1) {
        print('OrderBloc: Это первая страница, очищаем allOrders для statusId=${event.statusId}');
        allOrders[event.statusId] = [];
        allOrdersFetched[event.statusId] = false;
      }

      final existingOrderIds = (allOrders[event.statusId] ?? []).map((order) => order.id).toSet();
      final newOrders = orderResponse.data.where((order) => !existingOrderIds.contains(order.id)).toList();
      print('OrderBloc: Новые заказы: ${newOrders.map((o) => o.toJson()).toList()}');

      allOrders[event.statusId] = (allOrders[event.statusId] ?? []) + newOrders;
      allOrdersFetched[event.statusId] = newOrders.length < event.perPage || newOrders.isEmpty;
      print('OrderBloc: Обновлены allOrders для statusId=${event.statusId}: ${allOrders[event.statusId]!.map((o) => o.toJson()).toList()}');
      print('OrderBloc: allOrdersFetched[${event.statusId}] = ${allOrdersFetched[event.statusId]}');

      emit(OrderLoaded(
        statuses,
        orders: allOrders[event.statusId] ?? [],
        pagination: orderResponse.pagination,
      ));
      print('OrderBloc: Выдано состояние OrderLoaded с заказами: ${allOrders[event.statusId]!.map((o) => o.toJson()).toList()}');
    } catch (e) {
      if (state is! OrderStatusCreated) {
        print('OrderBloc: Ошибка при загрузке заказов: $e');
        emit(OrderError('Не удалось загрузить заказы: ${e.toString()}'));
      }
    }
  }

  Future<void> _fetchMoreOrders(FetchMoreOrders event, Emitter<OrderState> emit) async {
    print('OrderBloc: Начало _fetchMoreOrders для statusId=${event.statusId}, page=${event.page}');
    if (allOrdersFetched[event.statusId] == true || state is! OrderLoaded) {
      print('OrderBloc: Все заказы уже загружены или состояние не OrderLoaded, пропускаем');
      return;
    }

    try {
      final orderResponse = await apiService.getOrders(
        statusId: event.statusId,
        page: event.page,
        perPage: event.perPage,
      );
      print('OrderBloc: Получены дополнительные заказы: ${orderResponse.data.map((o) => o.toJson()).toList()}');

      final existingOrderIds = (allOrders[event.statusId] ?? []).map((order) => order.id).toSet();
      final newOrders = orderResponse.data.where((order) => !existingOrderIds.contains(order.id)).toList();
      print('OrderBloc: Новые дополнительные заказы: ${newOrders.map((o) => o.toJson()).toList()}');

      allOrders[event.statusId] = (allOrders[event.statusId] ?? []) + newOrders;
      allOrdersFetched[event.statusId] = newOrders.length < event.perPage || newOrders.isEmpty;
      print('OrderBloc: Обновлены allOrders для statusId=${event.statusId}: ${allOrders[event.statusId]!.map((o) => o.toJson()).toList()}');
      print('OrderBloc: allOrdersFetched[${event.statusId}] = ${allOrdersFetched[event.statusId]}');

      final currentState = state as OrderLoaded;
      emit(OrderLoaded(
        currentState.statuses,
        orders: allOrders[event.statusId] ?? [],
        pagination: orderResponse.pagination,
      ));
      print('OrderBloc: Выдано состояние OrderLoaded с дополнительными заказами');
    } catch (e) {
      if (state is! OrderStatusCreated) {
        print('OrderBloc: Ошибка при загрузке дополнительных заказов: $e');
        emit(OrderError('Не удалось загрузить дополнительные заказы: ${e.toString()}'));
      }
    }
  }

  Future<void> _fetchOrderDetails(FetchOrderDetails event, Emitter<OrderState> emit) async {
    print('OrderBloc: Начало _fetchOrderDetails для orderId=${event.orderId}');
    emit(OrderLoading());
    try {
      final statuses = await apiService.getOrderStatuses();
      print('OrderBloc: Получены статусы для деталей заказа: ${statuses.map((s) => s.toJson()).toList()}');
      final orderDetails = await apiService.getOrderDetails(event.orderId);
      print('OrderBloc: Получены детали заказа: ${orderDetails.toJson()}');
      emit(OrderLoaded(statuses, orderDetails: orderDetails));
      print('OrderBloc: Выдано состояние OrderLoaded с деталями заказа');
    } catch (e) {
      if (state is! OrderStatusCreated) {
        print('OrderBloc: Ошибка при загрузке деталей заказа: $e');
        emit(OrderError('Не удалось загрузить детали заказа: ${e.toString()}'));
      }
    }
  }

  Future<void> _createOrder(CreateOrder event, Emitter<OrderState> emit) async {
    print('OrderBloc: Начало _createOrder');
    emit(OrderLoading());
    try {
      final Map<String, dynamic> body = {
        'phone': event.phone,
        'lead_id': event.leadId,
        'deliveryType': event.delivery ? 'delivery' : 'pickup',
        'goods': event.goods,
        'organization_id': event.organizationId.toString(),
        'status_id': event.statusId,
      };

      if (event.delivery) {
        body['delivery_address'] = event.deliveryAddress;
      } else {
        body['delivery_address_id'] = null;
        body['branch_id'] = event.branchId?.toString();
        body['comment_to_courier'] = event.commentToCourier;
      }

      final result = await apiService.createOrder(
        phone: event.phone,
        leadId: event.leadId,
        delivery: event.delivery,
        deliveryAddress: event.deliveryAddress,
        goods: event.goods,
        organizationId: event.organizationId,
        statusId: event.statusId,
      );
      print('OrderBloc: Результат создания заказа: $result');

      if (result['success']) {
        final statusId = result['statusId'] ?? event.statusId;
        final orderData = result['order'];
        print('OrderBloc: Новый заказ создан, statusId=$statusId');

        final newOrder = Order.fromJson(orderData);
        print('OrderBloc: Новый заказ: ${newOrder.toJson()}');

        if (allOrders[statusId] == null) {
          allOrders[statusId] = [];
        }
        allOrders[statusId]!.insert(0, newOrder);
        print('OrderBloc: Добавлен новый заказ в allOrders[$statusId]: ${allOrders[statusId]!.map((o) => o.toJson()).toList()}');

        final statuses = await apiService.getOrderStatuses();
        print('OrderBloc: Получены статусы после создания заказа: ${statuses.map((s) => s.toJson()).toList()}');

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
        print('OrderBloc: Выдано состояние OrderLoaded после создания заказа');

        emit(OrderSuccess(statusId: statusId));
        print('OrderBloc: Выдано состояние OrderSuccess');
      } else {
        print('OrderBloc: Ошибка сервера при создании заказа: ${result['error']}');
        emit(OrderError('Не удалось создать заказ: ${result['error']}'));
      }
    } catch (e) {
      print('OrderBloc: Ошибка при создании заказа: $e');
      emit(OrderError('Ошибка создания заказа: $e'));
    }
  }

  Future<void> _updateOrder(UpdateOrder event, Emitter<OrderState> emit) async {
    print('OrderBloc: Начало _updateOrder для orderId=${event.orderId}');
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
        branchId: event.branchId,
        commentToCourier: event.commentToCourier,
      );
      print('OrderBloc: Ответ сервера на обновление заказа: $response');

      if (response['success']) {
        print('OrderBloc: Заказ успешно обновлен');
        emit(OrderSuccess());
      } else {
        print('OrderBloc: Ошибка сервера при обновлении заказа: ${response['error']}');
        emit(OrderError('Не удалось обновить заказ: ${response['error']}'));
      }
    } catch (e) {
      print('OrderBloc: Ошибка при обновлении заказа: $e');
      emit(OrderError('Ошибка при обновлении заказа: ${e.toString()}'));
    }
  }

  Future<void> _deleteOrder(DeleteOrder event, Emitter<OrderState> emit) async {
    print('OrderBloc: Начало _deleteOrder для orderId=${event.orderId}');
    emit(OrderLoading());
    try {
      final success = await apiService.deleteOrder(
        orderId: event.orderId,
        organizationId: event.organizationId,
      );
      print('OrderBloc: Результат удаления заказа: $success');
      if (success) {
        print('OrderBloc: Заказ успешно удален');
        emit(OrderSuccess());
      } else {
        print('OrderBloc: Ошибка сервера при удалении заказа');
        emit(OrderError('Не удалось удалить заказ'));
      }
    } catch (e) {
      print('OrderBloc: Ошибка при удалении заказа: $e');
      emit(OrderError('Ошибка удаления заказа: $e'));
    }
  }

  Future<void> _changeOrderStatus(ChangeOrderStatus event, Emitter<OrderState> emit) async {
    print('OrderBloc: Начало _changeOrderStatus для orderId=${event.orderId}, statusId=${event.statusId}');
    try {
      final success = await apiService.changeOrderStatus(
        orderId: event.orderId,
        statusId: event.statusId,
        organizationId: event.organizationId,
      );
      print('OrderBloc: Результат смены статуса заказа: $success');
      if (success) {
        final statuses = await apiService.getOrderStatuses();
        print('OrderBloc: Получены статусы после смены статуса: ${statuses.map((s) => s.toJson()).toList()}');
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
          print('OrderBloc: Обновленные заказы: ${updatedOrders.map((o) => o.toJson()).toList()}');
          emit(OrderLoaded(
            statuses,
            orders: updatedOrders,
            pagination: currentState.pagination,
          ));
          print('OrderBloc: Выдано состояние OrderLoaded после смены статуса');
        } else {
          emit(OrderLoaded(statuses));
          print('OrderBloc: Выдано состояние OrderLoaded с новыми статусами');
        }
      } else {
        print('OrderBloc: Ошибка сервера при смене статуса заказа');
        emit(OrderError('Не удалось сменить статус заказа: сервер вернул ошибку'));
      }
    } catch (e) {
      print('OrderBloc: Ошибка при смене статуса заказа: $e');
      emit(OrderError('Ошибка смены статуса заказа: $e'));
    }
  }

  Future<void> _createOrderStatus(CreateOrderStatus event, Emitter<OrderState> emit) async {
    print('OrderBloc: Начало _createOrderStatus с параметрами: title=${event.title}, notificationMessage=${event.notificationMessage}, isSuccess=${event.isSuccess}, isFailed=${event.isFailed}');
    emit(OrderLoading());
    print('OrderBloc: Установлено состояние OrderLoading');

    try {
      final response = await apiService.createOrderStatus(
        title: event.title,
        notificationMessage: event.notificationMessage,
        isSuccess: event.isSuccess,
        isFailed: event.isFailed,
      );
      print('OrderBloc: Ответ сервера на создание статуса: statusCode=${response.statusCode}, body=${response.body}');

      final statusCode = response.statusCode;
      print('Статус ответа! $statusCode');
      print('Тело ответа! ${response.body}');

      if (statusCode == 200 || statusCode == 201 || statusCode == 204) {
        int? newStatusId;

        if (response.body.isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            newStatusId = data['id'];
            print('OrderBloc: Получен newStatusId из ответа: $newStatusId');
          } catch (e) {
            print('OrderBloc: Ошибка декодирования тела ответа: $e');
          }
        }

        if (newStatusId == null) {
          print('OrderBloc: newStatusId не получен из ответа, запрашиваем FetchOrderStatuses');
          final statuses = await apiService.getOrderStatuses();
          print('OrderBloc: Получены статусы после FetchOrderStatuses: ${statuses.map((s) => s.toJson()).toList()}');
          if (statuses.isNotEmpty) {
            newStatusId = statuses.last.id;
            print('OrderBloc: Выбран последний статус как newStatusId: $newStatusId');
          } else {
            print('OrderBloc: Статусы пусты после FetchOrderStatuses');
            emit(OrderError('Не удалось определить ID нового статуса'));
            return;
          }
        }

        emit(OrderStatusCreated(
          'Статус заказа успешно создан',
          newStatusId: newStatusId,
        ));
        print('OrderBloc: Выдано состояние OrderStatusCreated с newStatusId=$newStatusId');

        await Future.delayed(Duration(milliseconds: 500));
        print('OrderBloc: Задержка завершена, добавляем событие FetchOrderStatuses');

        add(FetchOrderStatuses());
        print('OrderBloc: Добавлено событие FetchOrderStatuses');
      } else if (statusCode == 422) {
        print('OrderBloc: Ошибка валидации данных (422)');
        emit(OrderError('Ошибка валидации данных: проверьте введенные данные'));
      } else if (statusCode == 500) {
        print('OrderBloc: Ошибка сервера (500)');
        emit(OrderError('Ошибка сервера: попробуйте позже'));
      } else {
        print('OrderBloc: Неожиданный код ответа: $statusCode');
        emit(OrderError('Ошибка создания статуса заказа: код $statusCode'));
      }
    } catch (e) {
      print('OrderBloc: Ошибка при создании статуса заказа: $e');
      emit(OrderError('Ошибка создания статуса заказа: $e'));
    }
  }

  Future<void> _updateOrderStatus(UpdateOrderStatus event, Emitter<OrderState> emit) async {
    print('OrderBloc: Начало _updateOrderStatus для statusId=${event.statusId}');
    emit(OrderLoading());

    try {
      final response = await apiService.updateOrderStatus(
        statusId: event.statusId,
        title: event.title,
        notificationMessage: event.notificationMessage,
        isSuccess: event.isSuccess,
        isFailed: event.isFailed,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        emit(OrderStatusUpdated('Статус успешно обновлен'));
        add(FetchOrderStatuses());
      } else if (response.statusCode == 422) {
        emit(OrderError('Ошибка валидации данных: проверьте введенные данные'));
      } else if (response.statusCode == 500) {
        emit(OrderError('Ошибка сервера: попробуйте позже'));
      } else {
        emit(OrderError('Ошибка обновления статуса: код ${response.statusCode}'));
      }
    } catch (e) {
      emit(OrderError('Ошибка обновления статуса: $e'));
    }
  }

  Future<void> _deleteOrderStatus(DeleteOrderStatus event, Emitter<OrderState> emit) async {
    print('OrderBloc: Начало _deleteOrderStatus для statusId=${event.statusId}');
    emit(OrderLoading());

    try {
      final success = await apiService.deleteOrderStatus(event.statusId);
      if (success) {
        emit(OrderStatusDeleted(message: 'Статус успешно удален'));
      } else {
        emit(OrderError('Не удалось удалить статус'));
      }
    } catch (e) {
      emit(OrderError('Ошибка удаления статуса: $e'));
    }
  }
}