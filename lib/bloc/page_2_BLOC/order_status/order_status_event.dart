abstract class OrderEvent {}

class FetchOrderStatuses extends OrderEvent {}

class FetchOrders extends OrderEvent {
  final int? statusId;
  final int page;
  final int perPage;
  final String? query;
  final bool forceRefresh;

  FetchOrders({
    this.statusId,
    this.page = 1,
    this.perPage = 20,
    this.query,
    this.forceRefresh = false,
  });
}

class FetchMoreOrders extends OrderEvent {
  final int? statusId;
  final int page;
  final int perPage;
  final String? query;

  FetchMoreOrders({
    this.statusId,
    this.page = 1,
    this.perPage = 20,
    this.query,
  });
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
  final int statusId;
  final int? branchId; // Для самовывоза
  final String? commentToCourier; // Комментарий курьеру

  CreateOrder({
    required this.phone,
    required this.leadId,
    required this.delivery,
    required this.deliveryAddress,
    required this.goods,
    required this.organizationId,
    required this.statusId,
    this.branchId,
    this.commentToCourier,
  });
}
class UpdateOrder extends OrderEvent {
  final int orderId;
  final String phone;
  final int leadId;
  final bool delivery;
  final String deliveryAddress;
  final List<Map<String, dynamic>> goods;
  final int organizationId;
  final int? branchId; // Для самовывоза
  final String? commentToCourier; // Комментарий курьеру

  UpdateOrder({
    required this.orderId,
    required this.phone,
    required this.leadId,
    required this.delivery,
    required this.deliveryAddress,
    required this.goods,
    required this.organizationId,
    this.branchId,
    this.commentToCourier,
  });
}

class DeleteOrder extends OrderEvent {
  final int orderId;
  final int? organizationId;

  DeleteOrder({
    required this.orderId,
    this.organizationId,
  });
}

class ChangeOrderStatus extends OrderEvent {
  final int orderId;
  final int statusId;
  final int? organizationId;

  ChangeOrderStatus({
    required this.orderId,
    required this.statusId,
    this.organizationId,
  });
}