// lead_history_model.dart

class LeadHistory {
  final int id;
  final User? user;
  final String status;
  final DateTime date;
  final List<ChangeItem> changes; // ← ChangeItem

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
      final changes = changesJson
          .map((e) => ChangeItem.fromJson(e as Map<String, dynamic>))
          .where((c) => c.body.isNotEmpty)
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
    final bodyJson = json['body'] as Map<String, dynamic>? ?? {};
    final body = bodyJson.map((key, value) {
      return MapEntry(key, ChangeValue.fromJson(value));
    });
    return ChangeItem(
      id: json['id'] ?? 0,
      body: body,
    );
  }
}

class ChangeValue {
  final String? newValue;
  final String? previousValue;

  ChangeValue({this.newValue, this.previousValue});

  factory ChangeValue.fromJson(Map<String, dynamic> json) {
    return ChangeValue(
      newValue: json['new_value']?.toString(),
      previousValue: json['previous_value']?.toString(),
    );
  }
}