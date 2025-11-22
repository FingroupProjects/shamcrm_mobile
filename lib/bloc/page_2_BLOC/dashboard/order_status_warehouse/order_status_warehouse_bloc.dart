import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/order_status_warehouse/order_status_warehouse_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/order_status_warehouse/order_status_warehouse_state.dart';
import 'package:flutter/material.dart';


class OrderStatusWarehouseBloc extends Bloc<OrderStatusWarehouseEvent, OrderStatusWarehouseState> {
  final ApiService apiService;
  bool allOrderStatusWarehouseFetched = false;

  OrderStatusWarehouseBloc(this.apiService) : super(OrderStatusWarehouseInitial()) {
    on<FetchOrderStatusWarehouse>(_fetchOrderStatusWarehouse);
  }

  Future<void> _fetchOrderStatusWarehouse(FetchOrderStatusWarehouse event, Emitter<OrderStatusWarehouseState> emit) async {
    emit(OrderStatusWarehouseLoading());

    if (await _checkInternetConnection()) {
      try {
        final orderStatusWarehouse = await apiService.getOrderStatusWarehouse();
        allOrderStatusWarehouseFetched = orderStatusWarehouse.isEmpty;
        emit(OrderStatusWarehouseLoaded(orderStatusWarehouse));
      } catch (e) {
        debugPrint('Ошибка при загрузке статусов заказов!');  // Для отладки
        emit(OrderStatusWarehouseError('Не удалось загрузить список статусов заказов!'));
      }
    } else {
      emit(OrderStatusWarehouseError('Нет подключения к интернету'));
    }
  }

  // Method to check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}
