// models/changes.dart
import 'package:crm_task_manager/models/lead_history_model.dart';



class NoticeHistory {
  final int id;
  final String title;
  final List<HistoryItem> history;

  NoticeHistory({
    required this.id,
    required this.title,
    required this.history,
  });

  factory NoticeHistory.fromJson(Map<String, dynamic> json) {
    return NoticeHistory(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      history: (json['history'] as List?)
              ?.map((item) => HistoryItem.fromJson(item))
              .toList() ??
          [],
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
      title: json['title'] ?? '',
      history: (json['history'] as List?)
              ?.map((item) => HistoryItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class HistoryItem {
  final int id;
  final User user;
  final String status;
  final DateTime date;
  final List<ChangesLead> changes;  // используем ChangesLead для сделок

  HistoryItem({
    required this.id,
    required this.user,
    required this.status,
    required this.date,
    required this.changes,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? 0,
      user: User.fromJson(json['user'] ?? {}),
      status: json['status'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      changes: (json['changes'] is List)
          ? (json['changes'] as List)
              .map((item) => ChangesLead.fromJson(item))
              .toList()
          : [],
    );
  }
}
// models/changes_lead.dart
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
