class OrderStatus {
  final int id;
  final String name;
  final String? notificationMessage;
  final bool isSuccess;
  final bool isFailed;
  final bool canceled; // Новое поле
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderStatus({
    required this.id,
    required this.name,
    this.notificationMessage,
    this.isSuccess = false,
    this.isFailed = false,
    this.canceled = false, // Значение по умолчанию
    this.createdAt,
    this.updatedAt,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(
      id: json['id'] ?? 0,
      name: json['title'] ?? json['name'] ?? '',
      notificationMessage: json['notification_message'],
      // Преобразуем int (0 или 1) в bool
      isSuccess: (json['is_success'] ?? 0) == 1,
      isFailed: (json['is_failed'] ?? 0) == 1,
      canceled: (json['canceled'] ?? 0) == 1, // Преобразуем int в bool
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': name,
      'name': name,
      'notification_message': notificationMessage,
      'is_success': isSuccess ? 1 : 0, // Преобразуем bool в int для API
      'is_failed': isFailed ? 1 : 0,   // Преобразуем bool в int для API
      'canceled': canceled ? 1 : 0,    // Преобразуем bool в int для API
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}