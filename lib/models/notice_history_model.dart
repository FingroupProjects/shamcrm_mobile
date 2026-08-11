// models/changes.dart
import 'package:crm_task_manager/models/lead_history_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

class NoticeHistory {
  final int id;
  final String title;
  final List<HistoryItem> history;

  NoticeHistory({required this.id, required this.title, required this.history});

  factory NoticeHistory.fromJson(Map<String, dynamic> json) {
    final history = SafeConverters.toList(json['history'])
        .whereType<Map<String, dynamic>>()
        .map((e) => HistoryItem.fromJson(e))
        .toList();

    return NoticeHistory(
      id: SafeConverters.toInt(json['id']),
      title: SafeConverters.toSafeString(json['title'], defaultValue: 'Без названия'),
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
    final user = SafeConverters.toMapOrNull(userJson) != null
        ? User.fromJson(SafeConverters.toMap(userJson))
        : null;

    final changes = SafeConverters.toList(json['changes'])
        .whereType<Map<String, dynamic>>()
        .map((e) => ChangeItem.fromJson(e))
        .toList();

    return HistoryItem(
      id: SafeConverters.toInt(json['id']),
      user: user,
      status: SafeConverters.toSafeString(json['status']),
      date: SafeConverters.toDateTimeOrNull(json['date']) ?? DateTime.now(),
      changes: changes,
    );
  }
}
