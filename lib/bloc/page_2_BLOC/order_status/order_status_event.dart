// bloc/order/order_event.dart
abstract class OrderEvent {}

class FetchOrderStatuses extends OrderEvent {}

class FetchOrders extends OrderEvent {
  final int? statusId;
  final int page;
  final int perPage;

  FetchOrders({this.statusId, this.page = 1, this.perPage = 20});
}

class FetchOrderDetails extends OrderEvent {
  final int orderId;

  FetchOrderDetails(this.orderId);
}