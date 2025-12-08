import 'dart:convert';
import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/page_2/order/order_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final ApiService apiService;
  Map<int?, List<Order>> allOrders = {};
  Map<int?, bool> allOrdersFetched = {};
  Map<int, int> _orderCounts = {};
  bool isFetching = false;
  String? _currentQuery;
  List<String>? _currentManagerIds;
  List<String>? _currentLeadIds;
  DateTime? _currentFromDate;
  DateTime? _currentToDate;
  String? _currentStatus;
  String? _currentPaymentMethod;

  OrderBloc(this.apiService) : super(OrderInitial()) {
    on<FetchOrderStatuses>(_fetchOrderStatuses);
    on<FetchOrderStatusesWithFilters>(_fetchOrderStatusesWithFilters);
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
    on<AddMiniAppAddress>(_addMiniAppAddress);
  }

  bool get _hasActiveFilters {
    final bool listsOrQuery =
        (_currentQuery != null && _currentQuery!.isNotEmpty) ||
        (_currentManagerIds != null && _currentManagerIds!.isNotEmpty) ||
        (_currentLeadIds != null && _currentLeadIds!.isNotEmpty);

    final bool flagsOrDates =
        (_currentFromDate != null) ||
        (_currentToDate != null) ||
        (_currentStatus != null && _currentStatus!.isNotEmpty) ||
        (_currentPaymentMethod != null && _currentPaymentMethod!.isNotEmpty);

    return listsOrQuery || flagsOrDates;
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

Future<void> _fetchOrderStatuses(FetchOrderStatuses event, Emitter<OrderState> emit) async {
    emit(OrderLoading());

    try {
      List<OrderStatus> response;

      // При forceRefresh = true делаем РАДИКАЛЬНУЮ перезагрузку
      if (event.forceRefresh) {
        if (!await _checkInternetConnection()) {
          emit(OrderError('Нет подключения к интернету для обновления данных'));
          return;
        }
        
        // РАДИКАЛЬНАЯ очистка всех локальных данных блока
        _orderCounts.clear();
        allOrders.clear();
        allOrdersFetched.clear();
        isFetching = false;
        
        // Сбрасываем все параметры фильтрации
        _currentQuery = null;
        _currentManagerIds = null;
        _currentLeadIds = null;
        _currentFromDate = null;
        _currentToDate = null;
        _currentStatus = null;
        _currentPaymentMethod = null;
        
        // Загружаем статусы с сервера
        response = await apiService.getOrderStatuses();
        
        // ПОЛНОСТЬЮ перезаписываем кэш новыми данными
        await OrderCache.clearEverything();
        await OrderCache.cacheOrderStatuses(response.map((status) => {
          'id': status.id,
          'name': status.name,
          'orders_count': status.ordersCount,
        }).toList());
        
        // Устанавливаем новые счетчики ТОЛЬКО из свежих данных API
        for (var status in response) {
          _orderCounts[status.id] = status.ordersCount;
          await OrderCache.setPersistentOrderCount(status.id, status.ordersCount);
        }
        
      } else {
        // Стандартная логика для обычной загрузки
        if (!await _checkInternetConnection()) {
          final cachedStatuses = await OrderCache.getOrderStatuses();
          if (cachedStatuses.isNotEmpty) {
            // Восстанавливаем счетчики из кэша
            _orderCounts.clear();
            final allPersistentCounts = await OrderCache.getPersistentOrderCounts();
            for (String statusIdStr in allPersistentCounts.keys) {
              int statusId = int.parse(statusIdStr);
              int count = allPersistentCounts[statusIdStr] ?? 0;
              _orderCounts[statusId] = count;
            }
            
            // Создаём минимальные OrderStatus объекты для отображения
            final List<OrderStatus> minimalStatuses = cachedStatuses.map((status) {
              final statusId = status['id'] as int;
              final count = _orderCounts[statusId] ?? 0;
              return OrderStatus(
                id: statusId,
                name: status['name'] as String,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                isSuccess: false,
                isFailed: false,
                canceled: false,
                color: '#000000',
                position: 1,
                ordersCount: count,
              );
            }).toList();
            
            emit(OrderLoaded(minimalStatuses, orderCounts: Map.from(_orderCounts)));
          } else {
            emit(OrderError('Нет подключения к интернету и нет кэшированных данных'));
          }
          return;
        }

        // ВСЕГДА загружаем с API для получения актуальных счётчиков
        response = await apiService.getOrderStatuses();
        
        if (response.isEmpty) {
          debugPrint("OrderBloc: API returned empty statuses array");
          emit(OrderLoaded([], orderCounts: {}));
          return;
        }
        
        await OrderCache.cacheOrderStatuses(response.map((status) => {
          'id': status.id,
          'name': status.name,
          'orders_count': status.ordersCount,
        }).toList());

        // Устанавливаем счетчики из свежих данных API
        _orderCounts.clear();
        for (var status in response) {
          _orderCounts[status.id] = status.ordersCount;
          await OrderCache.setPersistentOrderCount(status.id, status.ordersCount);
        }
      }

      emit(OrderLoaded(response, orderCounts: Map.from(_orderCounts)));

      // При обычной загрузке автоматически загружаем заказы для первого статуса
      if (response.isNotEmpty && !event.forceRefresh && !_hasActiveFilters) {
        final firstStatusId = response.first.id;
        add(FetchOrders(statusId: firstStatusId));
      }

    } catch (e) {
      debugPrint('❌ OrderBloc: _fetchOrderStatuses - Error: $e');
      emit(OrderError('Не удалось загрузить статусы: $e'));
    }
  }

  Future<void> _fetchOrders(FetchOrders event, Emitter<OrderState> emit) async {
    if (isFetching) {
      debugPrint('⚠️ OrderBloc: _fetchOrders - Already fetching, skipping');
      return;
    }

    isFetching = true;

    debugPrint('🔍 OrderBloc: _fetchOrders - START');
    debugPrint('🔍 OrderBloc: statusId=${event.statusId}');

    try {
      if (state is! OrderLoaded || event.page == 1) {
        emit(OrderLoading());
      }

      // Сохраняем параметры текущего запроса
      _currentQuery = event.query;
      _currentManagerIds = event.managerIds;
      _currentLeadIds = event.leadIds;
      _currentFromDate = event.fromDate;
      _currentToDate = event.toDate;
      _currentStatus = event.status;
      _currentPaymentMethod = event.paymentMethod;

      // КРИТИЧНО: Восстанавливаем ВСЕ постоянные счетчики
      final allPersistentCounts = await OrderCache.getPersistentOrderCounts();
      for (String statusIdStr in allPersistentCounts.keys) {
        int statusId = int.parse(statusIdStr);
        int count = allPersistentCounts[statusIdStr] ?? 0;
        _orderCounts[statusId] = count;
      }

      debugPrint('✅ OrderBloc: Restored persistent counts: $_orderCounts');

      List<Order> orders = [];

      // Попытка загрузить из кэша
      if (event.statusId != null) {
        orders = await OrderCache.getOrdersForStatus(event.statusId);
        if (orders.isNotEmpty) {
          debugPrint('✅ OrderBloc: _fetchOrders - Emitting ${orders.length} cached orders for status ${event.statusId}');
          
          final statuses = await apiService.getOrderStatuses();
          emit(OrderLoaded(
            statuses,
            orders: orders,
            orderCounts: Map.from(_orderCounts),
          ));
        }
      }

      if (await _checkInternetConnection()) {
        debugPrint('📡 OrderBloc: Internet available, fetching from API');

        final statuses = await apiService.getOrderStatuses();
        final orderResponse = await apiService.getOrders(
          statusId: event.statusId,
          page: event.page,
          perPage: event.perPage,
          query: event.query,
          managerIds: event.managerIds,
          leadIds: event.leadIds,
          fromDate: event.fromDate,
          toDate: event.toDate,
          status: event.status,
          paymentMethod: event.paymentMethod,
        );

        if (event.page == 1) {
          allOrders[event.statusId] = [];
          allOrdersFetched[event.statusId] = false;
        }

        final existingOrderIds = (allOrders[event.statusId] ?? []).map((order) => order.id).toSet();
        final newOrders = orderResponse.data
            .where((order) => !existingOrderIds.contains(order.id))
            .toList();

        allOrders[event.statusId] = (allOrders[event.statusId] ?? []) + newOrders;
        allOrdersFetched[event.statusId] = newOrders.length < event.perPage || newOrders.isEmpty;

        debugPrint('✅ OrderBloc: Fetched ${newOrders.length} orders from API for status ${event.statusId}');

        // КЛЮЧЕВОЙ МОМЕНТ: Берём реальный счётчик из _orderCounts
        final int? realTotalCount = _orderCounts[event.statusId];
        
        debugPrint('🔍 OrderBloc: Real total count for status ${event.statusId}: $realTotalCount');

        // Кэшируем заказы с РЕАЛЬНЫМ общим счётчиком
        if (event.statusId != null) {
          await OrderCache.cacheOrdersForStatus(
            event.statusId,
            allOrders[event.statusId] ?? [],
            updatePersistentCount: true,
            actualTotalCount: realTotalCount,
          );
        }
        
        debugPrint('✅ OrderBloc: Cached ${(allOrders[event.statusId] ?? []).length} orders for status ${event.statusId}');

        emit(OrderLoaded(
          statuses,
          orders: allOrders[event.statusId] ?? [],
          pagination: orderResponse.pagination,
          orderCounts: Map.from(_orderCounts),
        ));
      } else {
        debugPrint('❌ OrderBloc: No internet connection');
      }

      debugPrint('✅ OrderBloc: _fetchOrders - Final orderCounts: $_orderCounts');

    } catch (e) {
      debugPrint('❌ OrderBloc: _fetchOrders - Error: $e');
      if (state is! OrderStatusCreated) {
        emit(OrderError('Не удалось загрузить заказы: ${e.toString()}'));
      }
    } finally {
      isFetching = false;
      debugPrint('🏁 OrderBloc: _fetchOrders - FINISHED');
    }
  }

  Future<void> _fetchMoreOrders(FetchMoreOrders event, Emitter<OrderState> emit) async {
    if (allOrdersFetched[event.statusId] == true || state is! OrderLoaded) {
      return;
    }

    try {
      final orderResponse = await apiService.getOrders(
        statusId: event.statusId,
        page: event.page,
        perPage: event.perPage,
        query: _currentQuery,
        managerIds: _currentManagerIds,
        leadIds: _currentLeadIds,
        fromDate: _currentFromDate,
        toDate: _currentToDate,
        status: _currentStatus,
        paymentMethod: _currentPaymentMethod,
      );

      final existingOrderIds = (allOrders[event.statusId] ?? []).map((order) => order.id).toSet();
      final newOrders = orderResponse.data
          .where((order) => !existingOrderIds.contains(order.id))
          .toList();

      allOrders[event.statusId] = (allOrders[event.statusId] ?? []) + newOrders;
      allOrdersFetched[event.statusId] = newOrders.length < event.perPage || newOrders.isEmpty;

      final currentState = state as OrderLoaded;
      emit(OrderLoaded(
        currentState.statuses,
        orders: allOrders[event.statusId] ?? [],
        pagination: orderResponse.pagination,
      ));
    } catch (e) {
      if (state is! OrderStatusCreated) {
        emit(OrderError('Не удалось загрузить дополнительные заказы: ${e.toString()}'));
      }
    }
  }
  Future<void> _fetchOrderDetails(
      FetchOrderDetails event, Emitter<OrderState> emit) async {
    // //print('OrderBloc: Начало _fetchOrderDetails для orderId=${event.orderId}');
    emit(OrderLoading());
    try {
      final statuses = await apiService.getOrderStatuses();
      // //print(
      //     'OrderBloc: Получены статусы для деталей заказа: ${statuses.map((s) => s.toJson()).toList()}');
      final orderDetails = await apiService.getOrderDetails(event.orderId);
      //print('OrderBloc: Получены детали заказа: ${orderDetails.toJson()}');
      emit(OrderLoaded(statuses, orderDetails: orderDetails));
      //print('OrderBloc: Выдано состояние OrderLoaded с деталями заказа');
    } catch (e) {
      if (state is! OrderStatusCreated) {
        //print('OrderBloc: Ошибка при загрузке деталей заказа: $e');
        emit(OrderError('Не удалось загрузить детали заказа: ${e.toString()}'));
      }
    }
  }

Future<void> _createOrder(CreateOrder event, Emitter<OrderState> emit) async {
  //print('OrderBloc: Начало _createOrder');
  emit(OrderLoading());
  try {
    final Map<String, dynamic> body = {
      'phone': event.phone,
      'lead_id': event.leadId,
      'deliveryType': event.delivery ? 'delivery' : 'pickup',
      'goods': event.goods,
      'organization_id': event.organizationId.toString(),
      'status_id': event.statusId,
      'comment_to_courier': event.commentToCourier,
      'manager_id': event.managerId?.toString(),
      'integration': null,
    };

    if (event.delivery) {
      body['delivery_address_id'] = event.deliveryAddressId?.toString();
    } else {
      body['delivery_address_id'] = null;
    }
    
    // Всегда отправляем branch_id, если он указан
    if (event.branchId != null) {
      body['branch_id'] = event.branchId.toString();
    }

    //print('OrderBloc: Тело запроса для создания заказа: ${jsonEncode(body)}');

    final result = await apiService.createOrder(
      phone: event.phone,
      leadId: event.leadId,
      delivery: event.delivery,
      deliveryAddress: event.deliveryAddress,
      deliveryAddressId: event.deliveryAddressId,
      goods: event.goods,
      organizationId: event.organizationId,
      statusId: event.statusId,
      branchId: event.branchId,
      commentToCourier: event.commentToCourier,
      managerId: event.managerId,
      integration: 1,
    );
    //print('OrderBloc: Результат создания заказа: $result');

    if (result['success']) {
      final statusId = result['statusId'] ?? event.statusId;
      //print('OrderBloc: Новый заказ создан, statusId=$statusId');

      // Эмитируем успех без создания объекта Order
      emit(OrderSuccess(statusId: statusId));
      //print('OrderBloc: Выдано состояние OrderSuccess');
    } else {
      //print('OrderBloc: Ошибка сервера при создании заказа: ${result['error']}');
      emit(OrderError('Не удалось создать заказ:'));
    }
  } catch (e, stackTrace) {
    //print('OrderBloc: Ошибка при создании заказа: $e');
    //print('OrderBloc: StackTrace: $stackTrace');
    emit(OrderError('Ошибка создания заказа'));
  }
}
Future<void> _updateOrder(UpdateOrder event, Emitter<OrderState> emit) async {
  //print('OrderBloc: Начало _updateOrder для orderId=${event.orderId}');
  emit(OrderLoading());
  try {
    final Map<String, dynamic> body = {
      'phone': event.phone,
      'lead_id': event.leadId,
      'deliveryType': event.delivery ? 'delivery' : 'pickup',
      'goods': event.goods,
      'organization_id': event.organizationId.toString(),
      'comment_to_courier': event.commentToCourier,
      'manager_id': event.managerId?.toString(),
    };

    if (event.delivery) {
      body['delivery_address'] = event.deliveryAddress;
      body['delivery_address_id'] = event.deliveryAddressId?.toString();
    } else {
      body['delivery_address'] = null;
      body['delivery_address_id'] = null;
    }
    
    // Всегда отправляем branch_id, если он указан
    if (event.branchId != null) {
      body['branch_id'] = event.branchId.toString();
    }

    //print('OrderBloc: Тело запроса для обновления заказа: ${jsonEncode(body)}');

    final response = await apiService.updateOrder(
      orderId: event.orderId,
      phone: event.phone,
      leadId: event.leadId,
      delivery: event.delivery,
      deliveryAddress: event.deliveryAddress,
      deliveryAddressId: event.deliveryAddressId,
      goods: event.goods,
      organizationId: event.organizationId,
      branchId: event.branchId,
      commentToCourier: event.commentToCourier,
      managerId: event.managerId,
    );
    //print('OrderBloc: Ответ сервера на обновление заказа: $response');

    if (response['success']) {
      //print('OrderBloc: Заказ успешно обновлен');
      final statusId = response['statusId'] ?? event.statusId;
      emit(OrderSuccess(statusId: statusId)); // Эмитируем успех с statusId
    } else {
      //print('OrderBloc: Ошибка сервера при обновлении заказа: ${response['error']}');
      emit(OrderError('Не удалось обновить заказ: ${response['error']}'));
    }
  } catch (e, stackTrace) {
    //print('OrderBloc: Ошибка при обновлении заказа: $e');
    //print('OrderBloc: StackTrace: $stackTrace');
    emit(OrderError('Ошибка при обновлении заказа: ${e.toString()}'));
  }
}
  Future<void> _deleteOrder(DeleteOrder event, Emitter<OrderState> emit) async {
    //print('OrderBloc: Начало _deleteOrder для orderId=${event.orderId}');
    emit(OrderLoading());
    try {
      final success = await apiService.deleteOrder(
        orderId: event.orderId,
        organizationId: event.organizationId,
      );
      //print('OrderBloc: Результат удаления заказа: $success');
      if (success) {
        //print('OrderBloc: Заказ успешно удален');
        emit(OrderSuccess());
      } else {
        //print('OrderBloc: Ошибка сервера при удалении заказа');
        emit(OrderError('Не удалось удалить заказ'));
      }
    } catch (e) {
      //print('OrderBloc: Ошибка при удалении заказа: $e');
      emit(OrderError('Ошибка удаления заказа: $e'));
    }
  }

  Future<void> _bushOrderStatus(
      ChangeOrderStatus event, Emitter<OrderState> emit) async {
    // //print(
    //     'OrderBloc: Начало _changeOrderStatus для orderId=${event.orderId}, statusId=${event.statusId}');
    try {
      final success = await apiService.changeOrderStatus(
        orderId: event.orderId,
        statusId: event.statusId,
        organizationId: event.organizationId,
      );
      // //print('OrderBloc: Результат смены статуса заказа: $success');
      if (success) {
        final statuses = await apiService.getOrderStatuses();
        // //print(
        //     'OrderBloc: Получены статусы после смены статуса: ${statuses.map((s) => s.toJson()).toList()}');
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
          // //print(
          //     'OrderBloc: Обновленные заказы: ${updatedOrders.map((o) => o.toJson()).toList()}');
          emit(OrderLoaded(
            statuses,
            orders: updatedOrders,
            pagination: currentState.pagination,
          ));
          //print('OrderBloc: Выдано состояние OrderLoaded после смены статуса');
        } else {
          emit(OrderLoaded(statuses));
          //print('OrderBloc: Выдано состояние OrderLoaded с новыми статусами');
        }
      } else {
        //print('OrderBloc: Ошибка сервера при смене статуса заказа');
        emit(OrderError(
            'Не удалось сменить статус заказа: сервер вернул ошибку'));
      }
    } catch (e) {
      //print('OrderBloc: Ошибка при смене статуса заказа: $e');
      emit(OrderError('Ошибка смены статуса заказа: $e'));
    }
  }

  Future<void> _createOrderStatus(
      CreateOrderStatus event, Emitter<OrderState> emit) async {
    // //print(
    //     'OrderBloc: Начало _createOrderStatus с параметрами: title=${event.title}, notificationMessage=${event.notificationMessage}, isSuccess=${event.isSuccess}, isFailed=${event.isFailed}');
    emit(OrderLoading());
    //print('OrderBloc: Установлено состояние OrderLoading');

    try {
      final response = await apiService.createOrderStatus(
        title: event.title,
        notificationMessage: event.notificationMessage,
        isSuccess: event.isSuccess,
        isFailed: event.isFailed,
      );
      // //print(
      //     'OrderBloc: Ответ сервера на создание статуса: statusCode=${response.statusCode}, body=${response.body}');

      final statusCode = response.statusCode;
      //print('Статус ответа! $statusCode');
      //print('Тело ответа! ${response.body}');

      if (statusCode == 200 || statusCode == 201 || statusCode == 204) {
        int? newStatusId;

        if (response.body.isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            newStatusId = data['id'];
            //print('OrderBloc: Получен newStatusId из ответа: $newStatusId');
          } catch (e) {
            //print('OrderBloc: Ошибка декодирования тела ответа: $e');
          }
        }

        if (newStatusId == null) {
          // //print(
          //     'OrderBloc: newStatusId не получен из ответа, запрашиваем FetchOrderStatuses');
          final statuses = await apiService.getOrderStatuses();
          // //print(
          //     'OrderBloc: Получены статусы после FetchOrderStatuses: ${statuses.map((s) => s.toJson()).toList()}');
          if (statuses.isNotEmpty) {
            newStatusId = statuses.last.id;
            // //print(
            //     'OrderBloc: Выбран последний статус как newStatusId: $newStatusId');
          } else {
            //print('OrderBloc: Статусы пусты после FetchOrderStatuses');
            emit(OrderError('Не удалось определить ID нового статуса'));
            return;
          }
        }

        emit(OrderStatusCreated(
          'Статус заказа успешно создан',
          newStatusId: newStatusId,
        ));
        // //print(
        //     'OrderBloc: Выдано состояние OrderStatusCreated с newStatusId=$newStatusId');

        await Future.delayed(Duration(milliseconds: 500));
        // //print(
        //     'OrderBloc: Задержка завершена, добавляем событие FetchOrderStatuses');

        add(FetchOrderStatuses());
        //print('OrderBloc: Добавлено событие FetchOrderStatuses');
      } else if (statusCode == 422) {
        //print('OrderBloc: Ошибка валидации данных (422)');
        emit(OrderError('Ошибка валидации данных: проверьте введенные данные'));
      } else if (statusCode == 500) {
        //print('OrderBloc: Ошибка сервера (500)');
        emit(OrderError('Ошибка сервера: попробуйте позже'));
      } else {
        //print('OrderBloc: Неожиданный код ответа: $statusCode');
        emit(OrderError('Ошибка создания статуса заказа: код $statusCode'));
      }
    } catch (e) {
      //print('OrderBloc: Ошибка при создании статуса заказа: $e');
      emit(OrderError('Ошибка создания статуса заказа: $e'));
    }
  }

  Future<void> _updateOrderStatus(
      UpdateOrderStatus event, Emitter<OrderState> emit) async {
    // //print(
    //     'OrderBloc: Начало _updateOrderStatus для statusId=${event.statusId}');
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
        emit(OrderError(
            'Ошибка обновления статуса: код ${response.statusCode}'));
      }
    } catch (e) {
      emit(OrderError('Ошибка обновления статуса: $e'));
    }
  }
 Future<void> _changeOrderStatus(ChangeOrderStatus event, Emitter<OrderState> emit) async {
  try {
    final success = await apiService.changeOrderStatus(
      orderId: event.orderId,
      statusId: event.statusId,
      organizationId: event.organizationId,
    );
    if (success) {
      if (state is OrderLoaded) {
        final currentState = state as OrderLoaded;
        final newStatus = currentState.statuses.firstWhere(
          (status) => status.id == event.statusId,
          orElse: () => throw Exception('Статус с id ${event.statusId} не найден'),
        );

        // Создаём новый список заказов, исключая заказ, который сменил статус
        final updatedOrders = currentState.orders
            .where((order) => order.id != event.orderId)
            .toList();

        // Получаем обновлённый заказ с сервера
        final updatedOrder = await apiService.getOrderDetails(event.orderId);

        // Добавляем обновлённый заказ в список
        updatedOrders.add(updatedOrder);

        emit(OrderLoaded(
          currentState.statuses, // Сохраняем текущие статусы без обновления
          orders: updatedOrders,
          pagination: currentState.pagination,
          orderDetails: currentState.orderDetails,
        ));

        // Обновляем заказы для текущего статуса
        add(FetchOrders(
          statusId: currentState.statuses.firstWhere(
              (status) => status.id == updatedOrder.orderStatus.id).id,
          page: 1,
          perPage: 20,
          forceRefresh: true,
          query: _currentQuery,
          managerIds: _currentManagerIds,
          leadIds: _currentLeadIds,
          fromDate: _currentFromDate,
          toDate: _currentToDate,
          status: _currentStatus,
          paymentMethod: _currentPaymentMethod,
        ));

        // Если статус изменился, обновляем заказы для старого статуса
        if (updatedOrder.orderStatus.id != event.statusId) {
          add(FetchOrders(
            statusId: event.statusId,
            page: 1,
            perPage: 20,
            forceRefresh: true,
            query: _currentQuery,
            managerIds: _currentManagerIds,
            leadIds: _currentLeadIds,
            fromDate: _currentFromDate,
            toDate: _currentToDate,
            status: _currentStatus,
            paymentMethod: _currentPaymentMethod,
          ));
        }
      } else {
        emit(OrderSuccess(statusId: event.statusId));
      }
    } else {
      emit(OrderError('Не удалось сменить статус заказа: сервер вернул ошибку'));
    }
  } catch (e) {
    emit(OrderError('Ошибка смены статуса заказа: $e'));
  }
}
  Future<void> _deleteOrderStatus(
      DeleteOrderStatus event, Emitter<OrderState> emit) async {
    // //print(
    //     'OrderBloc: Начало _deleteOrderStatus для statusId=${event.statusId}');
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

  Future<void> _addMiniAppAddress(AddMiniAppAddress event, Emitter<OrderState> emit) async {
    emit(OrderCreateAddressLoading());

    try {
      final response = await apiService.createDeliveryAddress(
        address: event.address,
        leadId: event.leadId,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(OrderCreateAddressSuccess());
      }
    } catch (e) {
      emit(OrderCreateAddressError('Ошибка создания адреса доставки: $e'));
    }
  }

  // ======================== ФИЛЬТРАЦИЯ СО СТАТУСАМИ ========================
  
  Future<void> _fetchOrderStatusesWithFilters(
    FetchOrderStatusesWithFilters event,
    Emitter<OrderState> emit,
  ) async {
    debugPrint('🔍 OrderBloc: _fetchOrderStatusesWithFilters - START');

    emit(OrderLoading());

    try {
      // 1. Получаем ВСЕ статусы (метод getOrderStatuses не поддерживает фильтры)
      final statuses = await apiService.getOrderStatuses();

      debugPrint('✅ OrderBloc: Got ${statuses.length} statuses');

      // 2. Обновляем счётчики из полученных статусов
      _orderCounts.clear();
      for (var status in statuses) {
        _orderCounts[status.id] = status.ordersCount;
        await OrderCache.setPersistentOrderCount(status.id, status.ordersCount);
      }

      // 3. Кэшируем статусы
      await OrderCache.cacheOrderStatuses(statuses.map((status) => {
        'id': status.id,
        'name': status.name,
        'orders_count': status.ordersCount,
      }).toList());

      // 4. Эмитим состояние со статусами
      emit(OrderLoaded(statuses, orderCounts: Map.from(_orderCounts)));

      // 5. СОХРАНЯЕМ ФИЛЬТРЫ В БЛОКЕ ПЕРЕД ПАРАЛЛЕЛЬНОЙ ЗАГРУЗКОЙ
      if (statuses.isNotEmpty) {
        debugPrint('🚀 OrderBloc: Starting parallel fetch for ${statuses.length} statuses');

        // Сохраняем фильтры для последующих запросов
        _currentQuery = null;
        _currentManagerIds = event.managerIds;
        _currentLeadIds = event.leadIds;
        _currentFromDate = event.fromDate;
        _currentToDate = event.toDate;
        _currentStatus = event.status;
        _currentPaymentMethod = event.paymentMethod;

        debugPrint('✅ OrderBloc: Filters saved to bloc state');

        // Создаём список Future для параллельной загрузки
        final List<Future<void>> fetchTasks = statuses.map((status) {
          return _fetchOrdersForStatusWithFilters(
            status.id,
            event.managerIds,
            event.leadIds,
            event.fromDate,
            event.toDate,
            event.status,
            event.paymentMethod,
          );
        }).toList();

        // Запускаем все запросы параллельно
        await Future.wait(fetchTasks);

        debugPrint('✅ OrderBloc: All parallel fetches completed');

        // После загрузки всех данных эмитим финальное состояние
        final allOrdersList = <Order>[];
        for (var status in statuses) {
          final ordersForStatus = await OrderCache.getOrdersForStatus(status.id);
          allOrdersList.addAll(ordersForStatus);
        }

        // Обновляем allOrders
        for (var status in statuses) {
          allOrders[status.id] = await OrderCache.getOrdersForStatus(status.id);
        }

        emit(OrderLoaded(
          statuses,
          orders: allOrdersList,
          orderCounts: Map.from(_orderCounts),
        ));
      }
    } catch (e) {
      debugPrint('❌ OrderBloc: _fetchOrderStatusesWithFilters - Error: $e');
      emit(OrderError('Не удалось загрузить статусы с фильтрами: $e'));
    }
  }

  // Вспомогательный метод для загрузки заказов одного статуса
  Future<void> _fetchOrdersForStatusWithFilters(
    int statusId,
    List<String>? managerIds,
    List<String>? leadIds,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    String? paymentMethod,
  ) async {
    try {
      if (!await _checkInternetConnection()) {
        debugPrint('⚠️ OrderBloc: No internet for status $statusId');
        return;
      }

      debugPrint('🔍 OrderBloc: _fetchOrdersForStatusWithFilters for status $statusId');

      final orderResponse = await apiService.getOrders(
        statusId: statusId,
        page: 1,
        perPage: 20,
        managerIds: managerIds,
        leadIds: leadIds,
        fromDate: fromDate,
        toDate: toDate,
        status: status,
        paymentMethod: paymentMethod,
      );

      debugPrint('✅ OrderBloc: Fetched ${orderResponse.data.length} orders for status $statusId WITH FILTERS');

      // Кэшируем с сохранением реального счётчика
      final realCount = _orderCounts[statusId];
      await OrderCache.cacheOrdersForStatus(
        statusId,
        orderResponse.data,
        updatePersistentCount: true,
        actualTotalCount: realCount,
      );
      
      // Обновляем allOrders для этого статуса
      allOrders[statusId] = orderResponse.data;
    } catch (e) {
      debugPrint('❌ OrderBloc: Error fetching orders for status $statusId: $e');
    }
  }

  // ======================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ========================
  
  /// РАДИКАЛЬНАЯ очистка - удаляет ВСЕ данные и сбрасывает состояние блока
  Future<void> clearAllCountsAndCache() async {
    // Очищаем локальные переменные блока
    _orderCounts.clear();
    allOrders.clear();
    allOrdersFetched.clear();
    isFetching = false;
    
    // Сбрасываем все текущие параметры фильтрации
    _currentQuery = null;
    _currentManagerIds = null;
    _currentLeadIds = null;
    _currentFromDate = null;
    _currentToDate = null;
    _currentStatus = null;
    _currentPaymentMethod = null;
    
    // Радикальная очистка кэша
    await OrderCache.clearEverything();
  }

  /// Дополнительный метод для принудительного сброса всех счетчиков
  Future<void> resetAllCounters() async {
    _orderCounts.clear();
    await OrderCache.clearPersistentCounts();
  }
  
  /// Метод для восстановления всех счетчиков из постоянного кэша
  Future<void> _restoreAllCounts() async {
    final allPersistentCounts = await OrderCache.getPersistentOrderCounts();
    _orderCounts.clear();
    
    for (String statusIdStr in allPersistentCounts.keys) {
      int statusId = int.parse(statusIdStr);
      int count = allPersistentCounts[statusIdStr] ?? 0;
      _orderCounts[statusId] = count;
    }
  }
}