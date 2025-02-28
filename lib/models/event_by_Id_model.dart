import 'package:crm_task_manager/models/event_model.dart';
import 'package:crm_task_manager/models/user.dart';

class Notice {
  final int id;
  final bool isFinished;
  final String title;
  final String body;
  final DateTime? date; // Поле может быть null
  final NoticeLead? lead;
  final NoticeAuthor? author; // Изменено на nullable
  final List<UserEvent> users;
  final bool sendNotification;
  final DateTime createdAt;
  final bool canFinish;
  final String? conclusion;
  Notice({
    required this.id,
    required this.isFinished,
    required this.title,
    required this.body,
    this.date,
    this.lead,
    this.conclusion,
    this.author, // Убрали required
    required this.users,
    required this.sendNotification,
    required this.createdAt,
    required this.canFinish,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    // Вспомогательная функция для парсинга пользователей
    List<UserEvent> parseUsers(dynamic usersJson) {
      if (usersJson == null) return [];
      if (usersJson is! List) return [];

      return List<UserEvent>.from(
        (usersJson as List).map((userJson) {
          if (userJson is Map<String, dynamic>) {
            return UserEvent.fromJson(userJson);
          }
          throw FormatException('Invalid user data format');
        }),
      );
    }

    try {
      return Notice(
        id: json['id'] as int? ?? 0,
        isFinished: json['is_finished'] as bool? ?? false,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        date: json['date'] != null
            ? DateTime.parse(json['date'].toString())
            : null,
        lead: json['lead'] != null
            ? NoticeLead.fromJson(json['lead'] as Map<String, dynamic>)
            : null,
        author: json['author'] != null
            ? NoticeAuthor.fromJson(json['author'] as Map<String, dynamic>)
            : null,
        users: parseUsers(json['users']),
        sendNotification: (json['send_notification'] as num?)?.toInt() == 1,
        createdAt: DateTime.parse(json['created_at'].toString()),
        canFinish: json['can_finish'] as bool? ?? false,
        conclusion: json['conclusion'] as String? ?? '',
      );
    } catch (e) {
      print('Error parsing Notice: $e');
      rethrow;
    }
  }
}

class UserEvent {
  final int id;
  final String name;
  final String lastname;
  final String login;
  final String email;
  final String phone;
  final String image;
  final DateTime? lastSeen;
  final DateTime? deletedAt;
  final String? telegramUserId;
  final String? jobTitle;
  final bool online;
  final String fullName;

  UserEvent({
    required this.id,
    required this.name,
    required this.lastname,
    required this.login,
    required this.email,
    required this.phone,
    required this.image,
    this.lastSeen,
    this.deletedAt,
    this.telegramUserId,
    this.jobTitle,
    required this.online,
    required this.fullName,
  });

  factory UserEvent.fromJson(Map<String, dynamic> json) {
    return UserEvent(
      id: json['id'],
      name: json['name'],
      lastname: json['lastname'],
      login: json['login'],
      email: json['email'],
      phone: json['phone'],
      image: json['image'],
      lastSeen:
          json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
      telegramUserId: json['telegram_user_id'],
      jobTitle: json['job_title'],
      online: json['online'],
      fullName: json['full_name'],
    );
  }
}
