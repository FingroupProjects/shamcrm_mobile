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
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      facebookLogin: json['facebook_login'] as String?,
      instaLogin: json['insta_login'] as String?,
      tgNick: json['tg_nick'] as String?,
      tgId: json['tg_id'] as String?,
      position: json['position'] as String?,
      manager: json['manager'] as String?,
      region: json['region'] as String?,
      waName: json['wa_name'] as String?,
      waPhone: json['wa_phone'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String? ?? '',
      birthday: json['birthday'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      dealsCount: json['deals_count'] as int? ?? 0,
      author: json['author'] as String?,
      email: json['email'] as String?,
      inProgressDealsCount: json['in_progress_deals_count'] as int? ?? 0,
      successfulDealsCount: json['successful_deals_count'] as int? ?? 0,
      failedDealsCount: json['failed_deals_count'] as int? ?? 0,
      sentTo1c: json['sent_to_1c'] as bool? ?? false,
      lastUpdate: json['last_update'] as int? ?? 0,
      messageStatus: json['messageStatus'] as String? ?? '',
    );
  }
}


