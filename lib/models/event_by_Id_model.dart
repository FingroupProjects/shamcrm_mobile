import 'package:crm_task_manager/models/event_model.dart';

class Notice {
  final int id;
  final bool isFinished;
  final String title;
  final String body;
  final DateTime? date;
  final NoticeLead? lead;
  final NoticeAuthor author;
  final List<dynamic> users;
  final bool sendNotification;
  final DateTime createdAt;
  final bool canFinish;

  Notice({
    required this.id,
    required this.isFinished,
    required this.title,
    required this.body,
    this.date,
    this.lead,
    required this.author,
    required this.users,
    required this.sendNotification,
    required this.createdAt,
    required this.canFinish,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'],
      isFinished: json['is_finished'],
      title: json['title'],
      body: json['body'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      lead: json['lead'] != null ? NoticeLead.fromJson(json['lead']) : null,
      author: NoticeAuthor.fromJson(json['author']),
      users: json['users'] ?? [],
      sendNotification: json['send_notification'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      canFinish: json['can_finish'],
    );
  }
}