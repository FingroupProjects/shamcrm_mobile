class DealHistory {
  final int id;
  final User user;
  final String status;
  final DateTime date;
  final Changes? changes;

  DealHistory({
    required this.id,
    required this.user,
    required this.status,
    required this.date,
    this.changes,
  });

  factory DealHistory.fromJson(Map<String, dynamic> json) {
  try {
    final userJson = json['user'];
    final user = userJson != null ? User.fromJson(userJson) : User(id: 0, name: 'Система', email: '', phone: '');

    return DealHistory(
      id: json['id'] ?? 0,
      user: user,
      status: json['status'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      changes: _parseChanges(json['changes']),
    );
  } catch (e) {
    print('Ошибка при парсинге DealHistory: $e');
    return DealHistory(
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
  final int? dealStatusNewValue; // Изменено на int
  final int? dealStatusPreviousValue; // Изменено на int
  final DateTime? statusUpdateDateNewValue;
  final DateTime? statusUpdateDatePreviousValue;
  final String? historyNameNewValue;
  final String? historyNamePreviousValue;
  final String? leadNewValue;
  final String? leadPreviousValue; 
  final String? managerNewValue;
  final String? managerPreviousValue;
  final String? startDateNewValue;
  final String? startDatePreviousValue;
  final String? endDateNewValue;
  final String? endDatePreviousValue;
  final String? sumNewValue;
  final String? sumPreviousValue;
  final String? descriptionNewValue;
  final String? descriptionPreviousValue;

  Changes({
    this.dealStatusNewValue,
    this.dealStatusPreviousValue,
    this.statusUpdateDateNewValue,
    this.statusUpdateDatePreviousValue,
    this.historyNameNewValue,
    this.historyNamePreviousValue,
    this.leadNewValue,
    this.leadPreviousValue,
    this.managerNewValue,
    this.managerPreviousValue,
    this.startDateNewValue,
    this.startDatePreviousValue,
    this.endDateNewValue,
    this.endDatePreviousValue,
    this.sumNewValue,
    this.sumPreviousValue,
    this.descriptionNewValue,
    this.descriptionPreviousValue,
  });

  factory Changes.fromJson(Map<String, dynamic> json) {
    return Changes(
      dealStatusNewValue: json['deal_status']?['new_value'] as int?, 
      dealStatusPreviousValue: json['deal_status']?['previous_value'] as int?, 
      statusUpdateDateNewValue: _parseDateTime(json['status_update_date']?['new_value']), 
      statusUpdateDatePreviousValue: _parseDateTime(json['status_update_date']?['previous_value']), 
      historyNameNewValue: json['name']?['new_value'] as String?,
      historyNamePreviousValue: json['name']?['previous_value'] as String?,
      leadNewValue: json['lead']?['new_value'] as String?, 
      leadPreviousValue: json['lead']?['previous_value'] as String?, 
      managerNewValue: json['manager']?['new_value'] as String?,
      managerPreviousValue: json['manager']?['previous_value'] as String?,
      startDateNewValue: json['start_date']?['new_value']?.toString(),
      startDatePreviousValue: json['start_date']?['previous_value']?.toString(),
      endDateNewValue: json['end_date']?['new_value']?.toString(),
      endDatePreviousValue: json['end_date']?['previous_value']?.toString(),
      sumNewValue: (json['sum']?['new_value']), 
      sumPreviousValue: (json['sum']?['previous_value']), 
      descriptionNewValue: json['description']?['new_value'] as String?,
      descriptionPreviousValue: json['description']?['previous_value'] as String?,
    );
  }


  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
