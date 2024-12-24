class DealHistory {
  final int id;
  final DealUser user;
  final String status;
  final DateTime date;
  final DealChanges? changes;

  DealHistory({
    required this.id,
    required this.user,
    required this.status,
    required this.date,
    this.changes,
  });

  factory DealHistory.fromJson(Map<String, dynamic> json) {
    try {
      // Проверка на наличие необходимых полей
      final userJson = json['user'];
      if (userJson == null) {
        throw FormatException('User data is null');
      }

      return DealHistory(
        id: json['id'] ?? 0,
        user: DealUser.fromJson(userJson),
        status: json['status'] ?? '', 
        date: json['date'] != null
            ? DateTime.parse(json['date'])
            : DateTime.now(),
        changes: _parseDealChanges(json['changes']),
      );
    } catch (e) {
      print('Ошибка при парсинге DealHistory: $e');
      return DealHistory(
        id: 0,
        user: DealUser(
            id: 0,
            name: 'Система',
            email: 'Не указано',
            phone: 'Не указано'),
        status: 'Создан',
        date: DateTime.now(),
        changes: null,
      );
    }
  }

  static DealChanges? _parseDealChanges(dynamic changesJson) {
    if (changesJson is List && changesJson.isNotEmpty) {
      final body = changesJson[0]['body'];
      if (body is Map<String, dynamic>) {
        return DealChanges.fromJson(body);
      }
    }
    return null;
  }
}

class DealUser {
  final int id;
  final String name;
  final String email;
  final String phone;

  DealUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory DealUser.fromJson(Map<String, dynamic> json) {
    return DealUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Не указано', 
      email: json['email'] ?? 'Не указано', 
      phone: json['phone'] ?? 'Не указано', 
    );
  }
}

class DealChanges {
  final String? dealStatusNewValue;
  final String? dealStatusPreviousValue;
  final int? positionNewValue;
  final int? positionPreviousValue;

  DealChanges({
    this.dealStatusNewValue,
    this.dealStatusPreviousValue,
    this.positionNewValue,
    this.positionPreviousValue,
  });

  factory DealChanges.fromJson(Map<String, dynamic> json) {
    return DealChanges(
      dealStatusNewValue: json['deal_status']?['new_value']?.toString(),
      dealStatusPreviousValue: json['deal_status']?['previous_value']?.toString(),
      positionNewValue: json['position']?['new_value'],
      positionPreviousValue: json['position']?['previous_value'],
    );
  }
}
