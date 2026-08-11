import 'package:crm_task_manager/models/event_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

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
  final bool sendSms;
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
    required this.sendSms,
    required this.createdAt,
    required this.canFinish,
    this.conclusion,
    this.call,
    this.files, // Добавляем в конструктор
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    try {
      final files = SafeConverters.toList(json['files'])
          .map((item) => NoticeFiles.fromJson(SafeConverters.toMap(item)))
          .toList();

      return Notice(
        id: SafeConverters.toInt(json['id']),
        isFinished: SafeConverters.toBool(json['is_finished']),
        title: SafeConverters.toSafeString(json['title']),
        body: SafeConverters.toSafeString(json['body']),
        date: SafeConverters.toDateTimeOrNull(json['date']),
        lead: SafeConverters.toMapOrNull(json['lead']) != null
            ? NoticeLead.fromJson(SafeConverters.toMap(json['lead']))
            : null,
        author: SafeConverters.toMapOrNull(json['author']) != null
            ? NoticeAuthor.fromJson(SafeConverters.toMap(json['author']))
            : null,
        users: SafeConverters.toList(json['users'])
            .map((userJson) => UserEvent.fromJson(SafeConverters.toMap(userJson)))
            .toList(),
        sendNotification: SafeConverters.toBool(json['send_notification']),
        sendSms: SafeConverters.toBool(json['send_sms']),
        createdAt: SafeConverters.toDateTime(json['created_at']),
        canFinish: SafeConverters.toBool(json['can_finish']),
        conclusion: SafeConverters.toStringOrNull(json['conclusion']),
        call: SafeConverters.toMapOrNull(json['call']) != null
            ? Call.fromJson(SafeConverters.toMap(json['call']))
            : null,
        files: files.isEmpty ? null : files,
      );
    } catch (e) {
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
  final String callRecordPath; // Оставляем для обратной совместимости
  final String? callRecordUrl; // Новое поле
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
    this.callRecordUrl, // Добавляем как опциональное
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
      id: SafeConverters.toInt(json['id']),
      linkedId: SafeConverters.toSafeString(json['linked_id']),
      caller: SafeConverters.toSafeString(json['caller']),
      trunk: SafeConverters.toSafeString(json['trunk']),
      organizationId: SafeConverters.toInt(json['organization_id']),
      leadId: SafeConverters.toInt(json['lead_id']),
      callRecordPath: SafeConverters.toSafeString(json['call_record_path']),
      callRecordUrl: SafeConverters.toStringOrNull(json['call_record_url']),
      userId: SafeConverters.toIntOrNull(json['user_id']),
      internalNumber: SafeConverters.toStringOrNull(json['internal_number']),
      callDuration: SafeConverters.toIntOrNull(json['call_duration']),
      callRingingDuration: SafeConverters.toIntOrNull(json['call_ringing_duration']),
      missed: SafeConverters.toBool(json['missed']),
      incoming: SafeConverters.toBool(json['incoming']),
      createdAt: SafeConverters.toDateTime(json['created_at']),
      updatedAt: SafeConverters.toDateTime(json['updated_at']),
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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      lastname: SafeConverters.toSafeString(json['lastname']),
      login: SafeConverters.toSafeString(json['login']),
      email: SafeConverters.toSafeString(json['email']),
      phone: SafeConverters.toSafeString(json['phone']),
      image: SafeConverters.toSafeString(json['image']),
      lastSeen: SafeConverters.toDateTimeOrNull(json['last_seen']),
      deletedAt: SafeConverters.toDateTimeOrNull(json['deleted_at']),
      telegramUserId: SafeConverters.toStringOrNull(json['telegram_user_id']),
      jobTitle: SafeConverters.toStringOrNull(json['job_title']),
      online: SafeConverters.toBool(json['online']),
      fullName: SafeConverters.toSafeString(json['full_name']),
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
    return NoticeFiles(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      path: SafeConverters.toSafeString(json['path']),
    );
  }
}
