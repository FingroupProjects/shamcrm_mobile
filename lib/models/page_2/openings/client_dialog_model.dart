import 'package:crm_task_manager/utils/safe_converters.dart';

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
      id: SafeConverters.toIntOrNull(json['id']),
      leadId: SafeConverters.toIntOrNull(json['lead_id']),
      name: SafeConverters.toStringOrNull(json['name']),
      sourceId: SafeConverters.toIntOrNull(json['source_id']),
      instaId: SafeConverters.toStringOrNull(json['insta_id']),
      instaLogin: SafeConverters.toStringOrNull(json['insta_login']),
      tgNick: SafeConverters.toStringOrNull(json['tg_nick']),
      tgId: SafeConverters.toStringOrNull(json['tg_id']),
      regionId: SafeConverters.toIntOrNull(json['region_id']),
      birthday: SafeConverters.toStringOrNull(json['birthday']),
      description: SafeConverters.toStringOrNull(json['description']),
      leadStatusId: SafeConverters.toIntOrNull(json['lead_status_id']),
      position: SafeConverters.toStringOrNull(json['position']),
      managerId: SafeConverters.toIntOrNull(json['manager_id']),
      waName: SafeConverters.toStringOrNull(json['wa_name']),
      waPhone: SafeConverters.toStringOrNull(json['wa_phone']),
      address: SafeConverters.toStringOrNull(json['address']),
      phone: SafeConverters.toStringOrNull(json['phone']),
      lead: SafeConverters.toStringOrNull(json['lead']),
      email: SafeConverters.toStringOrNull(json['email']),
      dialogState: SafeConverters.toStringOrNull(json['dialog_state']),
      organizationId: SafeConverters.toIntOrNull(json['organization_id']),
      sentTo1c: SafeConverters.toBoolOrNull(json['sent_to_1c']),
      createdAt: SafeConverters.toDateTimeOrNull(json['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(json['updated_at']),
      instagramPlatformIdId: SafeConverters.toIntOrNull(json['instagram_platform_id_id']),
      deletedAt: SafeConverters.toDateTimeOrNull(json['deleted_at']),
      authorId: SafeConverters.toIntOrNull(json['author_id']),
      processingSpeed: SafeConverters.toStringOrNull(json['processing_speed']),
      isClient: SafeConverters.toIntOrNull(json['is_client']),
      messageStatus: SafeConverters.toStringOrNull(json['messageStatus']),
      firstResponseAt: SafeConverters.toDateTimeOrNull(json['first_response_at']),
      shamId: SafeConverters.toIntOrNull(json['sham_id']),
      priceTypeId: SafeConverters.toIntOrNull(json['price_type_id']),
      verificationCode: SafeConverters.toStringOrNull(json['verification_code']),
      phoneVerifiedAt: SafeConverters.toDateTimeOrNull(json['phone_verified_at']),
      bonus: SafeConverters.toStringOrNull(json['bonus']),
      salesFunnelId: SafeConverters.toIntOrNull(json['sales_funnel_id']),
      activeScenarioExecutionId: SafeConverters.toIntOrNull(json['active_scenario_execution_id']),
      tiktokCommenterId: SafeConverters.toIntOrNull(json['tiktok_commenter_id']),
      token: SafeConverters.toStringOrNull(json['token']),
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
