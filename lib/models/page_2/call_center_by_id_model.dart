import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:crm_task_manager/utils/utf16_sanitizer.dart';

class CallById {
  final int id;
  final String linkedId;
  final String caller;
  final String destinationNumber;
  final String trunk;
  final int organizationId;
  final LeadByCall lead;
  final String callRecordUrl;
  final UserByCall? user;
  final int? internalNumber;
  final int? callDuration;
  final int? callRingingDuration;
  final bool incoming;
  final bool missed;
  final bool answered;
  final String callStatus;
  final DateTime callStartedAt;
  final DateTime? callAnsweredAt;
  final DateTime callEndedAt;
  final AdditionalData? additionalData;
  final String? rating;
  final String? report;
  final String createdAt;
  final String updatedAt;

  CallById({
    required this.id,
    required this.linkedId,
    required this.caller,
    required this.destinationNumber,
    required this.trunk,
    required this.organizationId,
    required this.lead,
    required this.callRecordUrl,
    this.user,
    this.internalNumber,
    this.callDuration,
    this.callRingingDuration,
    required this.incoming,
    required this.missed,
    required this.answered,
    required this.callStatus,
    required this.callStartedAt,
    this.callAnsweredAt,
    required this.callEndedAt,
    this.additionalData,
    this.rating,
    this.report,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CallById.fromJson(Map<String, dynamic> json) {
    DateTime? parseCustomDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        // Проверяем формат ISO 8601
        if (dateStr.contains('T') && dateStr.endsWith('Z')) {
          return DateTime.parse(dateStr);
        }
        // Обрабатываем нестандартный формат "YYYY-MM-DD HH:mm"
        final parts = dateStr.split(' ');
        if (parts.length != 2) return null;
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        if (dateParts.length != 3 || timeParts.length != 2) return null;
        return DateTime.utc(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
      } catch (e) {
        return null;
      }
    }

    return CallById(
      id: SafeConverters.toInt(json['id']),
      linkedId: SafeConverters.toSafeString(json['linked_id']),
      caller: SafeConverters.toSafeString(json['caller']),
      destinationNumber: SafeConverters.toSafeString(json['destination_number']),
      trunk: SafeConverters.toSafeString(json['trunk']),
      organizationId: SafeConverters.toInt(json['organization_id']),
      lead: LeadByCall.fromJson(SafeConverters.toMap(json['lead'])),
      callRecordUrl: SafeConverters.toSafeString(json['call_record_url']),
      user: SafeConverters.toMapOrNull(json['user']) != null
          ? UserByCall.fromJson(SafeConverters.toMap(json['user']))
          : null,
      internalNumber: SafeConverters.toIntOrNull(json['internal_number']),
      callDuration: SafeConverters.toIntOrNull(json['call_duration']),
      callRingingDuration: SafeConverters.toIntOrNull(json['call_ringing_duration']),
      incoming: SafeConverters.toBool(json['incoming']),
      missed: SafeConverters.toBool(json['missed']),
      answered: SafeConverters.toBool(json['answered']),
      callStatus: SafeConverters.toSafeString(json['call_status']),
      callStartedAt: parseCustomDate(SafeConverters.toStringOrNull(json['call_started_at']))
              ?.toLocal() ??
          DateTime.now(),
      callAnsweredAt: SafeConverters.toStringOrNull(json['call_answered_at']) != null
          ? parseCustomDate(SafeConverters.toStringOrNull(json['call_answered_at']))
              ?.toLocal()
          : null,
      callEndedAt: parseCustomDate(SafeConverters.toStringOrNull(json['call_ended_at']))
              ?.toLocal() ??
          DateTime.now(),
      additionalData: SafeConverters.toMapOrNull(json['additional_data']) != null
          ? AdditionalData.fromJson(
              SafeConverters.toMap(json['additional_data']))
          : null,
      rating: SafeConverters.toStringOrNull(json['rating']),
      report: SafeConverters.toStringOrNull(json['report']),
      createdAt: SafeConverters.toSafeString(json['created_at']),
      updatedAt: SafeConverters.toSafeString(json['updated_at']),
    );
  }
}

class LeadByCall {
  final int id;
  final String name;
  final String? facebookLogin;
  final String? instaLogin;
  final String? tgNick;
  final String? tgId;
  final List<dynamic> channels;
  final String? position;
  final String? waName;
  final String? waPhone;
  final String? address;
  final String phone;
  final String? birthday;
  final String? description;
  final String createdAt;
  final int? dealsCount;
  final String? email;
  final int? inProgressDealsCount;
  final int? successfulDealsCount;
  final int? failedDealsCount;
  final bool sentTo1c;
  final int lastUpdate;
  final String messageStatus;
  final String? file;
  final String? verificationCode;
  final String? phoneVerifiedAt;
  final String bonus;

  LeadByCall({
    required this.id,
    required this.name,
    this.facebookLogin,
    this.instaLogin,
    this.tgNick,
    this.tgId,
    required this.channels,
    this.position,
    this.waName,
    this.waPhone,
    this.address,
    required this.phone,
    this.birthday,
    this.description,
    required this.createdAt,
    this.dealsCount,
    this.email,
    this.inProgressDealsCount,
    this.successfulDealsCount,
    this.failedDealsCount,
    required this.sentTo1c,
    required this.lastUpdate,
    required this.messageStatus,
    this.file,
    this.verificationCode,
    this.phoneVerifiedAt,
    required this.bonus,
  });

  factory LeadByCall.fromJson(Map<String, dynamic> json) {
    return LeadByCall(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      facebookLogin: SafeConverters.toStringOrNull(json['facebook_login']),
      instaLogin: SafeConverters.toStringOrNull(json['insta_login']),
      tgNick: SafeConverters.toStringOrNull(json['tg_nick']),
      tgId: SafeConverters.toStringOrNull(json['tg_id']),
      channels: SafeConverters.toList(json['channels']),
      position: SafeConverters.toStringOrNull(json['position']),
      waName: SafeConverters.toStringOrNull(json['wa_name']),
      waPhone: SafeConverters.toStringOrNull(json['wa_phone']),
      address: SafeConverters.toStringOrNull(json['address']),
      phone: SafeConverters.toSafeString(json['phone']),
      birthday: SafeConverters.toStringOrNull(json['birthday']),
      description: SafeConverters.toStringOrNull(json['description']),
      createdAt: SafeConverters.toSafeString(json['created_at']),
      dealsCount: SafeConverters.toIntOrNull(json['deals_count']),
      email: SafeConverters.toStringOrNull(json['email']),
      inProgressDealsCount:
          SafeConverters.toIntOrNull(json['in_progress_deals_count']),
      successfulDealsCount:
          SafeConverters.toIntOrNull(json['successful_deals_count']),
      failedDealsCount: SafeConverters.toIntOrNull(json['failed_deals_count']),
      sentTo1c: SafeConverters.toBool(json['sent_to_1c']),
      lastUpdate: SafeConverters.toInt(json['last_update']),
      messageStatus: SafeConverters.toSafeString(json['messageStatus']),
      file: SafeConverters.toStringOrNull(json['file']),
      verificationCode: SafeConverters.toStringOrNull(json['verification_code']),
      phoneVerifiedAt: SafeConverters.toStringOrNull(json['phone_verified_at']),
      bonus: SafeConverters.toSafeString(json['bonus'], defaultValue: '0.00'),
    );
  }
}

class UserByCall {
  final int id;
  final String name;
  final String lastname;
  final String login;
  final String email;
  final String phone;
  final String image;
  final String? lastSeen;
  final String? deletedAt;
  final String telegramUserId;
  final String jobTitle;
  final bool online;
  final String fullName;
  final int isFirstLogin;
  final String uniqueId;

  UserByCall({
    required this.id,
    required this.name,
    required this.lastname,
    required this.login,
    required this.email,
    required this.phone,
    required this.image,
    this.lastSeen,
    this.deletedAt,
    required this.telegramUserId,
    required this.jobTitle,
    required this.online,
    required this.fullName,
    required this.isFirstLogin,
    required this.uniqueId,
  });

  factory UserByCall.fromJson(Map<String, dynamic> json) {
    String text(dynamic value) =>
        sanitizeUtf16(SafeConverters.toSafeString(value));

    return UserByCall(
      id: SafeConverters.toInt(json['id']),
      name: text(json['name']),
      lastname: text(json['lastname']),
      login: text(json['login']),
      email: text(json['email']),
      phone: text(json['phone']),
      image: text(json['image']),
      lastSeen: json['last_seen'] == null ? null : text(json['last_seen']),
      deletedAt: json['deleted_at'] == null ? null : text(json['deleted_at']),
      telegramUserId: text(json['telegram_user_id']),
      jobTitle: text(json['job_title']),
      online: SafeConverters.toBool(json['online']),
      fullName: text(json['full_name']),
      isFirstLogin: SafeConverters.toInt(json['is_first_login']),
      uniqueId: text(json['unique_id']),
    );
  }
}

class AdditionalData {
  final String userId;
  final String treeName;
  final String treeNumber;

  AdditionalData({
    required this.userId,
    required this.treeName,
    required this.treeNumber,
  });

  factory AdditionalData.fromJson(Map<String, dynamic> json) {
    return AdditionalData(
      userId: SafeConverters.toSafeString(json['user_id']),
      treeName: SafeConverters.toSafeString(json['treeName']),
      treeNumber: SafeConverters.toSafeString(json['treeNumber']),
    );
  }
}
