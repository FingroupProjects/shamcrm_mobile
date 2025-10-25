class Lead {
  final int? id;
  final int? leadId;
  final String? name;
  final int? sourceId;
  final String? instaId;
  final String? instaLogin;
  final String? tgNick;
  final String? tgId;
  final int? regionId;
  final String? birthday;
  final String? description;
  final int? leadStatusId;
  final String? position;
  final int? managerId;
  final String? waName;
  final String? waPhone;
  final String? address;
  final String? phone;
  final String? lead;
  final String? email;
  final String? dialogState;
  final int? organizationId;
  final bool? sentTo1c;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? instagramPlatformIdId;
  final DateTime? deletedAt;
  final int? authorId;
  final String? processingSpeed;
  final int? isClient;
  final String? messageStatus;
  final DateTime? firstResponseAt;
  final int? shamId;
  final int? priceTypeId;
  final String? verificationCode;
  final DateTime? phoneVerifiedAt;
  final String? bonus;
  final int? salesFunnelId;
  final int? activeScenarioExecutionId;
  final int? tiktokCommenterId;
  final String? token;

  Lead({
    this.id,
    this.leadId,
    this.name,
    this.sourceId,
    this.instaId,
    this.instaLogin,
    this.tgNick,
    this.tgId,
    this.regionId,
    this.birthday,
    this.description,
    this.leadStatusId,
    this.position,
    this.managerId,
    this.waName,
    this.waPhone,
    this.address,
    this.phone,
    this.lead,
    this.email,
    this.dialogState,
    this.organizationId,
    this.sentTo1c,
    this.createdAt,
    this.updatedAt,
    this.instagramPlatformIdId,
    this.deletedAt,
    this.authorId,
    this.processingSpeed,
    this.isClient,
    this.messageStatus,
    this.firstResponseAt,
    this.shamId,
    this.priceTypeId,
    this.verificationCode,
    this.phoneVerifiedAt,
    this.bonus,
    this.salesFunnelId,
    this.activeScenarioExecutionId,
    this.tiktokCommenterId,
    this.token,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as int?,
      leadId: json['lead_id'] as int?,
      name: json['name'] as String?,
      sourceId: json['source_id'] as int?,
      instaId: json['insta_id'] as String?,
      instaLogin: json['insta_login'] as String?,
      tgNick: json['tg_nick'] as String?,
      tgId: json['tg_id'] as String?,
      regionId: json['region_id'] as int?,
      birthday: json['birthday'] as String?,
      description: json['description'] as String?,
      leadStatusId: json['lead_status_id'] as int?,
      position: json['position'] as String?,
      managerId: json['manager_id'] as int?,
      waName: json['wa_name'] as String?,
      waPhone: json['wa_phone'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      lead: json['lead'] as String?,
      email: json['email'] as String?,
      dialogState: json['dialog_state'] as String?,
      organizationId: json['organization_id'] as int?,
      sentTo1c: json['sent_to_1c'] as bool?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      instagramPlatformIdId: json['instagram_platform_id_id'] as int?,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      authorId: json['author_id'] as int?,
      processingSpeed: json['processing_speed'] as String?,
      isClient: json['is_client'] as int?,
      messageStatus: json['messageStatus'] as String?,
      firstResponseAt: json['first_response_at'] != null
          ? DateTime.parse(json['first_response_at'] as String)
          : null,
      shamId: json['sham_id'] as int?,
      priceTypeId: json['price_type_id'] as int?,
      verificationCode: json['verification_code'] as String?,
      phoneVerifiedAt: json['phone_verified_at'] != null
          ? DateTime.parse(json['phone_verified_at'] as String)
          : null,
      bonus: json['bonus'] as String?,
      salesFunnelId: json['sales_funnel_id'] as int?,
      activeScenarioExecutionId: json['active_scenario_execution_id'] as int?,
      tiktokCommenterId: json['tiktok_commenter_id'] as int?,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_id': leadId,
      'name': name,
      'source_id': sourceId,
      'insta_id': instaId,
      'insta_login': instaLogin,
      'tg_nick': tgNick,
      'tg_id': tgId,
      'region_id': regionId,
      'birthday': birthday,
      'description': description,
      'lead_status_id': leadStatusId,
      'position': position,
      'manager_id': managerId,
      'wa_name': waName,
      'wa_phone': waPhone,
      'address': address,
      'phone': phone,
      'lead': lead,
      'email': email,
      'dialog_state': dialogState,
      'organization_id': organizationId,
      'sent_to_1c': sentTo1c,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'instagram_platform_id_id': instagramPlatformIdId,
      'deleted_at': deletedAt?.toIso8601String(),
      'author_id': authorId,
      'processing_speed': processingSpeed,
      'is_client': isClient,
      'messageStatus': messageStatus,
      'first_response_at': firstResponseAt?.toIso8601String(),
      'sham_id': shamId,
      'price_type_id': priceTypeId,
      'verification_code': verificationCode,
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
      'bonus': bonus,
      'sales_funnel_id': salesFunnelId,
      'active_scenario_execution_id': activeScenarioExecutionId,
      'tiktok_commenter_id': tiktokCommenterId,
      'token': token,
    };
  }

  Lead copyWith({
    int? id,
    int? leadId,
    String? name,
    int? sourceId,
    String? instaId,
    String? instaLogin,
    String? tgNick,
    String? tgId,
    int? regionId,
    String? birthday,
    String? description,
    int? leadStatusId,
    String? position,
    int? managerId,
    String? waName,
    String? waPhone,
    String? address,
    String? phone,
    String? lead,
    String? email,
    String? dialogState,
    int? organizationId,
    bool? sentTo1c,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? instagramPlatformIdId,
    DateTime? deletedAt,
    int? authorId,
    String? processingSpeed,
    int? isClient,
    String? messageStatus,
    DateTime? firstResponseAt,
    int? shamId,
    int? priceTypeId,
    String? verificationCode,
    DateTime? phoneVerifiedAt,
    String? bonus,
    int? salesFunnelId,
    int? activeScenarioExecutionId,
    int? tiktokCommenterId,
    String? token,
  }) {
    return Lead(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      name: name ?? this.name,
      sourceId: sourceId ?? this.sourceId,
      instaId: instaId ?? this.instaId,
      instaLogin: instaLogin ?? this.instaLogin,
      tgNick: tgNick ?? this.tgNick,
      tgId: tgId ?? this.tgId,
      regionId: regionId ?? this.regionId,
      birthday: birthday ?? this.birthday,
      description: description ?? this.description,
      leadStatusId: leadStatusId ?? this.leadStatusId,
      position: position ?? this.position,
      managerId: managerId ?? this.managerId,
      waName: waName ?? this.waName,
      waPhone: waPhone ?? this.waPhone,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      lead: lead ?? this.lead,
      email: email ?? this.email,
      dialogState: dialogState ?? this.dialogState,
      organizationId: organizationId ?? this.organizationId,
      sentTo1c: sentTo1c ?? this.sentTo1c,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      instagramPlatformIdId: instagramPlatformIdId ?? this.instagramPlatformIdId,
      deletedAt: deletedAt ?? this.deletedAt,
      authorId: authorId ?? this.authorId,
      processingSpeed: processingSpeed ?? this.processingSpeed,
      isClient: isClient ?? this.isClient,
      messageStatus: messageStatus ?? this.messageStatus,
      firstResponseAt: firstResponseAt ?? this.firstResponseAt,
      shamId: shamId ?? this.shamId,
      priceTypeId: priceTypeId ?? this.priceTypeId,
      verificationCode: verificationCode ?? this.verificationCode,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      bonus: bonus ?? this.bonus,
      salesFunnelId: salesFunnelId ?? this.salesFunnelId,
      activeScenarioExecutionId: activeScenarioExecutionId ?? this.activeScenarioExecutionId,
      tiktokCommenterId: tiktokCommenterId ?? this.tiktokCommenterId,
      token: token ?? this.token,
    );
  }
}