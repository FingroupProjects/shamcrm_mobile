import 'package:crm_task_manager/models/lead_history_model.dart';

class TaskHistory {
  final int id;
  final User user;
  final String status;
  final DateTime date;
  final List<ChangeItem> changes; // Используем ChangeItem!

  TaskHistory({
    required this.id,
    required this.user,
    required this.status,
    required this.date,
    required this.changes,
  });

  factory TaskHistory.fromJson(Map<String, dynamic> json) {
    try {
      final userJson = json['user'];
      final user = userJson != null 
          ? User.fromJson(userJson) 
          : User(id: 0, name: 'Система', email: '', phone: '');

      final changesJson = json['changes'] as List<dynamic>? ?? [];
      final changes = changesJson
          .map((item) => ChangeItem.fromJson(item))
          .toList();

      return TaskHistory(
        id: json['id'] ?? 0,
        user: user,
        status: json['status'] ?? '',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        changes: changes,
      );
    } catch (e) {
      return TaskHistory(
        id: 0,
        user: User(id: 0, name: 'Система', email: '', phone: ''),
        status: 'Создано',
        date: DateTime.now(),
        changes: [],
      );
    }
  }
}