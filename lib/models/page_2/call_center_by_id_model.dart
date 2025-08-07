
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
  DateTime? _parseCustomDate(String? dateStr) {
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
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    linkedId: json['linked_id']?.toString() ?? '',
    caller: json['caller']?.toString() ?? '',
    destinationNumber: json['destination_number']?.toString() ?? '',
    trunk: json['trunk']?.toString() ?? '',
    organizationId: json['organization_id'] is int
        ? json['organization_id']
        : int.parse(json['organization_id']?.toString() ?? '0'),
    lead: LeadByCall.fromJson(json['lead'] as Map<String, dynamic>),
    callRecordUrl: json['call_record_url']?.toString() ?? '',
    user: json['user'] != null
        ? UserByCall.fromJson(json['user'] as Map<String, dynamic>)
        : null,
    internalNumber: json['internal_number'] != null
        ? json['internal_number'] is int
            ? json['internal_number']
            : int.tryParse(json['internal_number'].toString())
        : null,
    callDuration: json['call_duration'] != null
        ? json['call_duration'] is int
            ? json['call_duration']
            : int.tryParse(json['call_duration'].toString())
        : null,
    callRingingDuration: json['call_ringing_duration'] != null
        ? json['call_ringing_duration'] is int
            ? json['call_ringing_duration']
            : int.tryParse(json['call_ringing_duration'].toString())
        : null,
    incoming: json['incoming'] as bool? ?? false,
    missed: json['missed'] as bool? ?? false,
    answered: json['answered'] as bool? ?? false,
    callStatus: json['call_status']?.toString() ?? '',
    callStartedAt: _parseCustomDate(json['call_started_at']?.toString()) ??
        DateTime.utc(1970, 1, 1, 0, 0),
    callAnsweredAt: json['call_answered_at'] != null
        ? _parseCustomDate(json['call_answered_at']?.toString())
        : null,
    callEndedAt: _parseCustomDate(json['call_ended_at']?.toString()) ??
        DateTime.utc(1970, 1, 1, 0, 0),
    additionalData: json['additional_data'] != null
        ? AdditionalData.fromJson(json['additional_data'] as Map<String, dynamic>)
        : null,
    rating: json['rating']?.toString(),
    report: json['report']?.toString(),
    createdAt: json['created_at']?.toString() ?? '',
    updatedAt: json['updated_at']?.toString() ?? '',
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
    id: json['id'] is int ? json['id'] : int.parse(json['id']?.toString() ?? '0'),
    name: json['name']?.toString() ?? '',
    facebookLogin: json['facebook_login']?.toString(),
    instaLogin: json['insta_login']?.toString(),
    tgNick: json['tg_nick']?.toString(),
    tgId: json['tg_id']?.toString(),
    channels: json['channels'] as List<dynamic>? ?? [],
    position: json['position']?.toString(),
    waName: json['wa_name']?.toString(),
    waPhone: json['wa_phone']?.toString(),
    address: json['address']?.toString(),
    phone: json['phone']?.toString() ?? '',
    birthday: json['birthday']?.toString(),
    description: json['description']?.toString(),
    createdAt: json['created_at']?.toString() ?? '',
    dealsCount: json['deals_count'] is int ? json['deals_count'] : int.tryParse(json['deals_count']?.toString() ?? ''),
    email: json['email']?.toString(),
    inProgressDealsCount: json['in_progress_deals_count'] is int
        ? json['in_progress_deals_count']
        : int.tryParse(json['in_progress_deals_count']?.toString() ?? ''),
    successfulDealsCount: json['successful_deals_count'] is int
        ? json['successful_deals_count']
        : int.tryParse(json['successful_deals_count']?.toString() ?? ''),
    failedDealsCount: json['failed_deals_count'] is int
        ? json['failed_deals_count']
        : int.tryParse(json['failed_deals_count']?.toString() ?? ''),
    sentTo1c: json['sent_to_1c'] as bool? ?? false,
    lastUpdate: json['last_update'] is int ? json['last_update'] : int.parse(json['last_update']?.toString() ?? '0'),
    messageStatus: json['messageStatus']?.toString() ?? '',
    file: json['file']?.toString(),
    verificationCode: json['verification_code']?.toString(),
    phoneVerifiedAt: json['phone_verified_at']?.toString(),
    bonus: json['bonus']?.toString() ?? '0.00',
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
    return UserByCall(
      id: json['id'] as int,
      name: json['name'] as String,
      lastname: json['lastname'] as String,
      login: json['login'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      image: json['image'] as String,
      lastSeen: json['last_seen'] as String?,
      deletedAt: json['deleted_at'] as String?,
      telegramUserId: json['telegram_user_id'] as String,
      jobTitle: json['job_title'] as String,
      online: json['online'] as bool,
      fullName: json['full_name'] as String,
      isFirstLogin: json['is_first_login'] as int,
      uniqueId: json['unique_id'] as String,
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
      userId: json['user_id'] as String,
      treeName: json['treeName'] as String,
      treeNumber: json['treeNumber'] as String,
    );
  }
}