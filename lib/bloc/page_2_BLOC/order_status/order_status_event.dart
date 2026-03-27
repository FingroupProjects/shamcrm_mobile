abstract class OrderEvent {}

class FetchOrderStatuses extends OrderEvent {
  final bool forceRefresh;

  FetchOrderStatuses({this.forceRefresh = false});
}

class FetchOrderStatusesWithFilters extends OrderEvent {
  final List<String>? managerIds;
  final List<String>? regionsIds;
  final List<String>? leadIds;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? status;
  final String? paymentMethod;

  FetchOrderStatusesWithFilters({
    this.managerIds,
    this.regionsIds,
    this.leadIds,
    this.fromDate,
    this.toDate,
    this.status,
    this.paymentMethod,
  });
}

class FetchOrders extends OrderEvent {
  final int? statusId;
  final int page;
  final int perPage;
  final String? query;
  final bool forceRefresh;
  final List<String>? managerIds;
  final List<String>? regionsIds;
  final List<String>? leadIds;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? status;
  final String? paymentMethod;

  FetchOrders({
    this.statusId,
    this.page = 1,
    this.perPage = 20,
    this.query,
    this.forceRefresh = false,
    this.managerIds,
    this.regionsIds,
    this.leadIds,
    this.fromDate,
    this.toDate,
    this.status,
    this.paymentMethod,
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
  final String? deliveryAddress;
  final int? deliveryAddressId;
  final List<Map<String, dynamic>> goods;
  final int organizationId;
  final int statusId;
  final int? branchId;
  final String? commentToCourier;
  final int? managerId; // Новое поле
  final double sum;

  CreateOrder({
    required this.phone,
    required this.leadId,
    required this.delivery,
    this.deliveryAddress,
    this.deliveryAddressId,
    required this.goods,
    required this.organizationId,
    required this.statusId,
    this.branchId,
    this.commentToCourier,
    this.managerId, // Добавляем в конструктор
    required this.sum,
  });
}
class UpdateOrder extends OrderEvent {
  final int orderId;
  final String phone;
  final int leadId;
  final bool delivery;
  final String? deliveryAddress;
  final int? deliveryAddressId;
  final List<Map<String, dynamic>> goods;
  final int organizationId;
  final int? branchId;
  final String? commentToCourier;
  final int? managerId; // Новое поле
  final int? statusId; // Добавлено для обновления списка
  final double sum;

  UpdateOrder({
    required this.orderId,
    required this.phone,
    required this.leadId,
    required this.delivery,
    this.deliveryAddress,
    this.deliveryAddressId,
    required this.goods,
    required this.organizationId,
    this.branchId,
    this.commentToCourier,
    this.managerId,
    this.statusId,
    required this.sum,
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

class CreateOrderStatus extends OrderEvent {
  final String title;
  final String notificationMessage;
  final bool isSuccess;
  final bool isFailed;

  CreateOrderStatus({
    required this.title,
    required this.notificationMessage,
    required this.isSuccess,
    required this.isFailed,
  });
}

class UpdateOrderStatus extends OrderEvent {
  final int statusId;
  final String title;
  final String notificationMessage;
  final bool isSuccess;
  final bool isFailed;

  UpdateOrderStatus({
    required this.statusId,
    required this.title,
    required this.notificationMessage,
    required this.isSuccess,
    required this.isFailed,
  });
}

class DeleteOrderStatus extends OrderEvent {
  final int statusId;

  DeleteOrderStatus({required this.statusId});
}

class AddMiniAppAddress extends OrderEvent {
  final String address;
  final int leadId;

  AddMiniAppAddress({
    required this.address,
    required this.leadId,
  });
}
