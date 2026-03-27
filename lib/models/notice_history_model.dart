// models/changes.dart
import 'package:crm_task_manager/models/lead_history_model.dart';

class NoticeHistory {
  final int id;
  final String title;
  final List<HistoryItem> history;

  NoticeHistory({required this.id, required this.title, required this.history});

  factory NoticeHistory.fromJson(Map<String, dynamic> json) {
    final historyJson = json['history'] as List<dynamic>? ?? [];
    final history = historyJson
        .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return NoticeHistory(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Без названия',
      history: history,
    );
  }
}

class HistoryItem {
  final int id;
  final User? user;
  final String status;
  final DateTime date;
  final List<ChangeItem> changes;

  HistoryItem({
    required this.id,
    this.user,
    required this.status,
    required this.date,
    required this.changes,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final user = userJson != null ? User.fromJson(userJson) : null;

    final changesJson = json['changes'] as List<dynamic>? ?? [];
    // Убрали фильтрацию - сохраняем все changes
    final changes = changesJson
        .map((e) => ChangeItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return HistoryItem(
      id: json['id'] ?? 0,
      user: user,
      status: json['status'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      changes: changes,
    );
  }
}
