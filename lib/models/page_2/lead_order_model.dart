import 'package:crm_task_manager/utils/safe_converters.dart';

class LeadOrderData {
  final int id;
  final String name;
  final String? facebookLogin;
  final String? instaLogin;
  final String? tgNick;
  final String? tgId;
  final String? position;
  final String? manager;
  final String? region;
  final String? waName;
  final String? waPhone;
  final String? address;
  final String? phone;
  final String? birthday;
  final String? description;
  final String createdAt;
  final int dealsCount;
  final String? author;
  final String? email;
  final int inProgressDealsCount;
  final int successfulDealsCount;
  final int failedDealsCount;
  final bool sentTo1c;
  final int lastUpdate;
  final String messageStatus;

  LeadOrderData({
    required this.id,
    required this.name,
    this.facebookLogin,
    this.instaLogin,
    this.tgNick,
    this.tgId,
    this.position,
    this.manager,
    this.region,
    this.waName,
    this.waPhone,
    this.address,
    this.phone,
    this.birthday,
    this.description,
    required this.createdAt,
    required this.dealsCount,
    this.author,
    this.email,
    required this.inProgressDealsCount,
    required this.successfulDealsCount,
    required this.failedDealsCount,
    required this.sentTo1c,
    required this.lastUpdate,
    required this.messageStatus,
  });

  factory LeadOrderData.fromJson(Map<String, dynamic> json) {
    return LeadOrderData(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      facebookLogin: SafeConverters.toStringOrNull(json['facebook_login']),
      instaLogin: SafeConverters.toStringOrNull(json['insta_login']),
      tgNick: SafeConverters.toStringOrNull(json['tg_nick']),
      tgId: SafeConverters.toStringOrNull(json['tg_id']),
      position: SafeConverters.toStringOrNull(json['position']),
      manager: SafeConverters.toStringOrNull(json['manager']),
      region: SafeConverters.toStringOrNull(json['region']),
      waName: SafeConverters.toStringOrNull(json['wa_name']),
      waPhone: SafeConverters.toStringOrNull(json['wa_phone']),
      address: SafeConverters.toStringOrNull(json['address']),
      phone: SafeConverters.toSafeString(json['phone']),
      birthday: SafeConverters.toStringOrNull(json['birthday']),
      description: SafeConverters.toStringOrNull(json['description']),
      createdAt: SafeConverters.toSafeString(json['created_at']),
      dealsCount: SafeConverters.toInt(json['deals_count']),
      author: SafeConverters.toStringOrNull(json['author']),
      email: SafeConverters.toStringOrNull(json['email']),
      inProgressDealsCount: SafeConverters.toInt(json['in_progress_deals_count']),
      successfulDealsCount: SafeConverters.toInt(json['successful_deals_count']),
      failedDealsCount: SafeConverters.toInt(json['failed_deals_count']),
      sentTo1c: SafeConverters.toBool(json['sent_to_1c']),
      lastUpdate: SafeConverters.toInt(json['last_update']),
      messageStatus: SafeConverters.toSafeString(json['messageStatus']),
    );
  }
}

