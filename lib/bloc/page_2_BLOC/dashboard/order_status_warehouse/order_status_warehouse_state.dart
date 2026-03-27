import 'package:crm_task_manager/models/page_2/order_status_warehouse_model.dart';

abstract class OrderStatusWarehouseState {}

class OrderStatusWarehouseInitial extends OrderStatusWarehouseState {}

class OrderStatusWarehouseLoading extends OrderStatusWarehouseState {}

class OrderStatusWarehouseLoaded extends OrderStatusWarehouseState {
  final List<OrderStatusWarehouse> orderStatusWarehouse;

  OrderStatusWarehouseLoaded(this.orderStatusWarehouse);
}

class OrderStatusWarehouseError extends OrderStatusWarehouseState {
  final String message;

  OrderStatusWarehouseError(this.message);
}

class OrderStatusWarehouseSuccess extends OrderStatusWarehouseState {
  final String message;

  OrderStatusWarehouseSuccess(this.message);
}
