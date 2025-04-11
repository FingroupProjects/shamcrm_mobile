// bloc/order/order_state.dart
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';

abstract class OrderState {}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final List<OrderStatus> statuses;
  final List<Order> orders;
  final Pagination? pagination;
  final Order? orderDetails;

  OrderLoaded(this.statuses, {this.orders = const [], this.pagination, this.orderDetails});
}

class OrderError extends OrderState {
  final String message;
   OrderError(this.message);
}

class OrderSuccess extends OrderState {
  final int? statusId; // Добавляем поле для статуса заказа
  OrderSuccess({this.statusId});
}