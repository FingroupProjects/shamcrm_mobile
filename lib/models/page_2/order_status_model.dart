class OrderStatus {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSuccess;
  final bool isFailed;
  final bool canceled;
  final String? notificationMessage;
  final String color;
  final int position;
  final int ordersCount; // Новое поле

  OrderStatus({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.isSuccess,
    required this.isFailed,
    required this.canceled,
    this.notificationMessage,
    required this.color,
    required this.position,
    required this.ordersCount, // Добавляем в конструктор
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toString()),
      isSuccess: json['is_success'] == 1,
      isFailed: json['is_failed'] == 1,
      canceled: json['canceled'] == 1,
      notificationMessage: json['notification_message'],
      color: json['color'] ?? '#000',
      position: json['position'] ?? 0,
      ordersCount: json['orders_count'] ?? 0, // Читаем orders_count
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_success': isSuccess ? 1 : 0,
      'is_failed': isFailed ? 1 : 0,
      'canceled': canceled ? 1 : 0,
      'notification_message': notificationMessage,
      'color': color,
      'position': position,
      'orders_count': ordersCount, // Добавляем в JSON
    };
  }
}