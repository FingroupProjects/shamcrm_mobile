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
  final Map<int, int> orderCounts;

  OrderLoaded(
    this.statuses, {
    this.orders = const [],
    this.pagination,
    this.orderDetails,
    this.orderCounts = const {},
  });
}

class OrderError extends OrderState {
  final String message;
  OrderError(this.message);
}

class OrderSuccess extends OrderState {
  final int? statusId;
  OrderSuccess({this.statusId});
}

class OrderStatusCreated extends OrderState {
  final String message;
  final int newStatusId;

  OrderStatusCreated(this.message, {required this.newStatusId});
}

class OrderStatusUpdated extends OrderState {
  final String message;

  OrderStatusUpdated(this.message);
}

class OrderStatusDeleted extends OrderState {
  final String message;

  OrderStatusDeleted({required this.message});
}

class OrderCreateAddressLoading extends OrderState {}

class OrderCreateAddressSuccess extends OrderState {
  final String message;

  OrderCreateAddressSuccess({this.message = 'Адрес доставки успешно создан'});
}

class OrderCreateAddressError extends OrderState {
  final String message;

  OrderCreateAddressError(this.message);
}