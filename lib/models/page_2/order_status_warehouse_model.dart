
class OrderStatusWarehouse {
  final int id;
  final String name;
  final String? createdAt;
  final String? updatedAt;
  final int isSuccess;
  final int isDelivered;
  final int isFailed;
  final int canceled;
  final String notificationMessage;
  final String color;
  final int position;
  final int ordersCount;

  OrderStatusWarehouse({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    required this.isSuccess,
    required this.isDelivered,
    required this.isFailed,
    required this.canceled,
    required this.notificationMessage,
    required this.color,
    required this.position,
    required this.ordersCount,
  });

  factory OrderStatusWarehouse.fromJson(Map<String, dynamic> json) {
    return OrderStatusWarehouse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      isSuccess: json['is_success'] ?? 0,
      isDelivered: json['is_delivered'] ?? 0,
      isFailed: json['is_failed'] ?? 0,
      canceled: json['canceled'] ?? 0,
      notificationMessage: json['notification_message'] ?? '',
      color: json['color'] ?? '',
      position: json['position'] ?? 0,
      ordersCount: json['orders_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_success': isSuccess,
      'is_delivered': isDelivered,
      'is_failed': isFailed,
      'canceled': canceled,
      'notification_message': notificationMessage,
      'color': color,
      'position': position,
      'orders_count': ordersCount,
    };
  }
}
