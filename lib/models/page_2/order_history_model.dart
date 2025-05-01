class OrderHistory {
  final int id;
  final User user;
  final String status;
  final DateTime date;
  final Changes? changes;

  OrderHistory({
    required this.id,
    required this.user,
    required this.status,
    required this.date,
    this.changes,
  });

  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    try {
      final userJson = json['user'];
      final user = userJson != null
          ? User.fromJson(userJson)
          : User(id: 0, name: 'Система', email: '', phone: '');

      return OrderHistory(
        id: json['id'] ?? 0,
        user: user,
        status: json['status'] ?? '',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        changes: _parseChanges(json['changes']),
      );
    } catch (e) {
      print('Ошибка при парсинге OrderHistory: $e');
      return OrderHistory(
        id: 0,
        user: User(id: 0, name: 'Система', email: 'Не указано', phone: 'Не указано'),
        status: 'Создан',
        date: DateTime.now(),
        changes: null,
      );
    }
  }

  static Changes? _parseChanges(dynamic changesJson) {
    if (changesJson is List && changesJson.isNotEmpty) {
      final body = changesJson[0]['body'];
      if (body != null && body is Map<String, dynamic>) {
        return Changes.fromJson(body);
      }
    }
    return null;
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Система',
      email: json['email'] ?? 'Не указано',
      phone: json['phone'] ?? 'Не указано',
    );
  }
}

class Changes {
  final String? leadNewValue;
  final String? leadPreviousValue;
  final String? deliveryTypeNewValue;
  final String? deliveryTypePreviousValue;

  Changes({
    this.leadNewValue,
    this.leadPreviousValue,
    this.deliveryTypeNewValue,
    this.deliveryTypePreviousValue,
  });

  factory Changes.fromJson(Map<String, dynamic> json) {
    return Changes(
      leadNewValue: json['lead']?['new_value'] as String?,
      leadPreviousValue: json['lead']?['previous_value'] as String?,
      deliveryTypeNewValue: json['deliveryType']?['new_value'] as String?,
      deliveryTypePreviousValue: json['deliveryType']?['previous_value'] as String?,
    );
  }
}