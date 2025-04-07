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

class CreateOrder extends OrderEvent {
  final String phone;
  final int leadId;
  final bool delivery;
  final String deliveryAddress;
  final List<Map<String, dynamic>> goods;
  final int organizationId;

  CreateOrder({
    required this.phone,
    required this.leadId,
    required this.delivery,
    required this.deliveryAddress,
    required this.goods,
    required this.organizationId,
  });
}