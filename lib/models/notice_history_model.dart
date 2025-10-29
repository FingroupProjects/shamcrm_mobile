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
// models/deal_history.dart
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
    final changes = changesJson
        .map((e) => ChangeItem.fromJson(e as Map<String, dynamic>))
        .where((c) => c.body.isNotEmpty)
        .toList();

    return HistoryItem(
      id: json['id'] ?? 0,
      user: user,
      status: json['status'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      changes: changes,
    );
  }
}// models/changes_lead.dart
class ChangesLead {
  final int id;
  final Map<String, dynamic> body;

  ChangesLead({
    required this.id,
    required this.body,
  });

  factory ChangesLead.fromJson(Map<String, dynamic> json) {
    final rawBody = json['body'];
    Map<String, dynamic> bodyMap = {};

    if (rawBody is Map<String, dynamic>) {
      bodyMap = rawBody;
    } else if (rawBody is List && rawBody.isNotEmpty) {
      // Если список не пустой, можно добавить дополнительную обработку.
      bodyMap = {};
    }

    return ChangesLead(
      id: json['id'] ?? 0,
      body: bodyMap,
    );
  }
}
