

import 'package:crm_task_manager/models/lead_history_model.dart';
import 'package:crm_task_manager/models/notice_history_model.dart';

class DealHistoryLead {
  final int id;
  final String title;
  final List<HistoryItem> history;

  DealHistoryLead({
    required this.id,
    required this.title,
    required this.history,
  });

  factory DealHistoryLead.fromJson(Map<String, dynamic> json) {
    return DealHistoryLead(
      id: json['id'] ?? 0,
      title: json['name'] ?? '',
      history: (json['history'] as List?)
              ?.map((item) => HistoryItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class DealHistory {
  final int id;
  final User user;
  final String status;
  final DateTime date;
  final List<ChangeItem> changes;

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
      final user = userJson != null 
          ? User.fromJson(userJson) 
          : User(id: 0, name: 'Система', email: '', phone: '');

      final changesJson = json['changes'] as List<dynamic>? ?? [];
      // Убрали фильтрацию - сохраняем все changes
      final changes = changesJson
          .map((item) => ChangeItem.fromJson(item))
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