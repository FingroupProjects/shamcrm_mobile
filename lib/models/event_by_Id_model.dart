import 'package:crm_task_manager/models/event_model.dart';

class Notice {
  final int id;
  final bool isFinished;
  final String title;
  final String body;
  final DateTime? date;
  final NoticeLead? lead;
  final NoticeAuthor? author;
  final List<UserEvent> users;
  final bool sendNotification;
  final DateTime createdAt;
  final bool canFinish;
  final String? conclusion;
  final Call? call;
  final List<NoticeFiles>? files; // Новое поле для файлов

  Notice({
    required this.id,
    required this.isFinished,
    required this.title,
    required this.body,
    this.date,
    this.lead,
    this.author,
    required this.users,
    required this.sendNotification,
    required this.createdAt,
    required this.canFinish,
    this.conclusion,
    this.call,
    this.files, // Добавляем в конструктор
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
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
      final files = (json['files'] as List<dynamic>?)
              ?.map((item) => NoticeFiles.fromJson(item))
              .toList() ??
          []; // Парсим файлы
      print('Notice: Parsed files: $files');

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
        conclusion: json['conclusion'] as String?,
        call: json['call'] != null
            ? Call.fromJson(json['call'] as Map<String, dynamic>)
            : null,
        files: files, // Добавляем файлы
      );
    } catch (e) {
      print('Error parsing Notice: $e');
      rethrow;
    }
  }
}

class Call {
  final int id;
  final String linkedId;
  final String caller;
  final String trunk;
  final int organizationId;
  final int leadId;
  final String callRecordPath;
  final int? userId;
  final String? internalNumber;
  final int? callDuration;
  final int? callRingingDuration;
  final bool missed;
  final bool incoming;
  final DateTime createdAt;
  final DateTime updatedAt;

  Call({
    required this.id,
    required this.linkedId,
    required this.caller,
    required this.trunk,
    required this.organizationId,
    required this.leadId,
    required this.callRecordPath,
    this.userId,
    this.internalNumber,
    this.callDuration,
    this.callRingingDuration,
    required this.missed,
    required this.incoming,
    required this.createdAt,
    required this.updatedAt,
  });

 factory Call.fromJson(Map<String, dynamic> json) {
  return Call(
    id: json['id'] as int? ?? 0,
    linkedId: json['linked_id'] as String? ?? '',
    caller: json['caller'] as String? ?? '',
    trunk: json['trunk'] as String? ?? '',
    organizationId: json['organization_id'] as int? ?? 0,
    leadId: json['lead_id'] as int? ?? 0,
    callRecordPath: json['call_record_path'] as String? ?? '',
    userId: json['user_id'] as int?,
    internalNumber: json['internal_number']?.toString(), 
    callDuration: json['call_duration'] as int?,
    callRingingDuration: json['call_ringing_duration'] as int?,
    missed: json['missed'] as bool? ?? false,
    incoming: json['incoming'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'].toString()),
    updatedAt: DateTime.parse(json['updated_at'].toString()),
  );
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
class NoticeFiles {
  final int id;
  final String name;
  final String path;

  NoticeFiles({
    required this.id,
    required this.name,
    required this.path,
  });

  factory NoticeFiles.fromJson(Map<String, dynamic> json) {
    print('NoticeFiles: Parsing JSON for file ID: ${json['id']}');
    final file = NoticeFiles(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name'] is String ? json['name'] : '',
      path: json['path'] is String ? json['path'] : '',
    );
    print('NoticeFiles: File created: id=${file.id}, name=${file.name}, path=${file.path}');
    return file;
  }
}