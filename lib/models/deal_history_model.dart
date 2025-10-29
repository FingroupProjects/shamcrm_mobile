import 'package:crm_task_manager/models/notice_history_model.dart';

class DealHistory {
  final int id;
  final User user;
  final String status;
  final DateTime date;
  final List<ChangesLead> changes; // Теперь список!

  DealHistory({
    required this.id,
    required this.user,
    required this.status,
    required this.date,
    required this.changes,
  });

  factory DealHistory.fromJson(Map<String, dynamic> json) {
    try {
      final userJson = json['user'];
      final user = userJson != null ? User.fromJson(userJson) : User(id: 0, name: 'Система', email: '', phone: '');

      final changesJson = json['changes'] as List<dynamic>? ?? [];
      final changes = changesJson
          .map((item) => ChangesLead.fromJson(item))
          .where((c) => c.body.isNotEmpty)
          .toList();

      return DealHistory(
        id: json['id'] ?? 0,
        user: user,
        status: json['status'] ?? '',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        changes: changes,
      );
    } catch (e) {
      return DealHistory(
        id: 0,
        user: User(id: 0, name: 'Система', email: '', phone: ''),
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
  final String full_name;

  User({
    required this.id,
    required this.name,
    this.lastname = '',
    required this.email,
    required this.phone,
  }) : full_name = '$name $lastname'.trim();

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