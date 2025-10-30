// ==========================================
// models/lead_history_model.dart
// ==========================================

class LeadHistory {
  final int id;
  final User? user;
  final String status;
  final DateTime date;
  final List<ChangeItem> changes;

  LeadHistory({
    required this.id,
    this.user,
    required this.status,
    required this.date,
    required this.changes,
  });

  factory LeadHistory.fromJson(Map<String, dynamic> json) {
    try {
      final userJson = json['user'];
      final user = userJson != null ? User.fromJson(userJson) : null;

      final changesJson = json['changes'] as List<dynamic>? ?? [];
      // Убрали фильтрацию - сохраняем все changes
      final changes = changesJson
          .map((e) => ChangeItem.fromJson(e as Map<String, dynamic>))
          .toList();

      return LeadHistory(
        id: json['id'] ?? 0,
        user: user,
        status: json['status'] ?? '',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        changes: changes,
      );
    } catch (e) {
      print('Ошибка парсинга LeadHistory: $e');
      return LeadHistory(
        id: 0,
        user: null,
        status: 'Создан',
        date: DateTime.now(),
        changes: [],
      );
    }
  }
}

class User {
  final int id;
  final String name;
  final String lastname;
  final String email;
  final String phone;
  final String fullName;

  User({
    required this.id,
    required this.name,
    this.lastname = '',
    required this.email,
    required this.phone,
  }) : fullName = '$name $lastname'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Система',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class ChangeItem {
  final int id;
  final Map<String, ChangeValue> body;

  ChangeItem({required this.id, required this.body});

  factory ChangeItem.fromJson(Map<String, dynamic> json) {
    final rawBody = json['body'];
    Map<String, ChangeValue> bodyMap = {};

    if (rawBody is Map<String, dynamic>) {
      // Преобразуем каждое поле в ChangeValue
      bodyMap = rawBody.map((key, value) {
        if (value is Map<String, dynamic>) {
          return MapEntry(key, ChangeValue.fromJson(value));
        } else {
          // Если не Map, создаём пустой ChangeValue
          return MapEntry(key, ChangeValue(newValue: null, previousValue: null));
        }
      });
    } else if (rawBody is List) {
      // Если body - массив (может быть пустым)
      if (rawBody.isNotEmpty && rawBody.first is Map<String, dynamic>) {
        final firstMap = rawBody.first as Map<String, dynamic>;
        bodyMap = firstMap.map((key, value) {
          if (value is Map<String, dynamic>) {
            return MapEntry(key, ChangeValue.fromJson(value));
          } else {
            return MapEntry(key, ChangeValue(newValue: null, previousValue: null));
          }
        });
      }
      // Если массив пустой, оставляем bodyMap пустым
    }

    return ChangeItem(
      id: json['id'] ?? 0,
      body: bodyMap,
    );
  }
}

class ChangeValue {
  final String? newValue;
  final String? previousValue;

  ChangeValue({this.newValue, this.previousValue});

  factory ChangeValue.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return ChangeValue(
        newValue: json['new_value']?.toString(),
        previousValue: json['previous_value']?.toString(),
      );
    }
    return ChangeValue(newValue: null, previousValue: null);
  }
}