class ClientOpeningsResponse {
  final List<ClientOpening>? result;
  final dynamic errors;

  ClientOpeningsResponse({
    this.result,
    this.errors,
  });

  factory ClientOpeningsResponse.fromJson(Map<String, dynamic> json) {
    return ClientOpeningsResponse(
      result: json["result"] == null
          ? []
          : List<ClientOpening>.from(
              json["result"]!.map((x) => ClientOpening.fromJson(x))),
      errors: json["errors"],
    );
  }
}

class ClientOpening {
  final int id;
  final String counterpartyType;
  final int counterpartyId;
  final String ourDuty;
  final String debtToUs;
  final int? counterpartySettlementId;
  final int organizationId;
  final String createdAt;
  final String updatedAt;
  final ClientCounterparty counterparty;

  ClientOpening({
    required this.id,
    required this.counterpartyType,
    required this.counterpartyId,
    required this.ourDuty,
    required this.debtToUs,
    this.counterpartySettlementId,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
    required this.counterparty,
  });

  factory ClientOpening.fromJson(Map<String, dynamic> json) {
    return ClientOpening(
      id: json['id'] as int,
      counterpartyType: json['counterparty_type'] as String,
      counterpartyId: json['counterparty_id'] as int,
      ourDuty: json['our_duty'] as String,
      debtToUs: json['debt_to_us'] as String,
      counterpartySettlementId: json['counterparty_settlement_id'] as int?,
      organizationId: json['organization_id'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      counterparty: ClientCounterparty.fromJson(json['counterparty'] as Map<String, dynamic>),
    );
  }
}

class ClientCounterparty {
  final int id;
  final int? leadId;
  final String name;
  final int sourceId;
  final String? instaId;
  final String? instaLogin;
  final String? tgNick;
  final String? tgId;
  final int? regionId;
  final String? birthday;
  final String? description;
  final int leadStatusId;
  final int position;
  final int? managerId;
  final String? waName;
  final String? waPhone;
  final String? address;
  final String phone;
  final String? lead;
  final String? email;
  final String dialogState;
  final int organizationId;
  final bool sentTo1c;
  final String createdAt;
  final String updatedAt;
  final int? instagramPlatformIdId;
  final String? deletedAt;
  final int authorId;
  final int processingSpeed;
  final int isClient;
  final String messageStatus;
  final String? firstResponseAt;
  final String? shamId;
  final int? priceTypeId;
  final String? verificationCode;
  final String? phoneVerifiedAt;
  final String bonus;
  final int salesFunnelId;
  final int? activeScenarioExecutionId;
  final int? tiktokCommenterId;
  final String? token;

  ClientCounterparty({
    required this.id,
    this.leadId,
    required this.name,
    required this.sourceId,
    this.instaId,
    this.instaLogin,
    this.tgNick,
    this.tgId,
    this.regionId,
    this.birthday,
    this.description,
    required this.leadStatusId,
    required this.position,
    this.managerId,
    this.waName,
    this.waPhone,
    this.address,
    required this.phone,
    this.lead,
    this.email,
    required this.dialogState,
    required this.organizationId,
    required this.sentTo1c,
    required this.createdAt,
    required this.updatedAt,
    this.instagramPlatformIdId,
    this.deletedAt,
    required this.authorId,
    required this.processingSpeed,
    required this.isClient,
    required this.messageStatus,
    this.firstResponseAt,
    this.shamId,
    this.priceTypeId,
    this.verificationCode,
    this.phoneVerifiedAt,
    required this.bonus,
    required this.salesFunnelId,
    this.activeScenarioExecutionId,
    this.tiktokCommenterId,
    this.token,
  });

  factory ClientCounterparty.fromJson(Map<String, dynamic> json) {
    return ClientCounterparty(
      id: json['id'] as int,
      leadId: json['lead_id'] as int?,
      name: json['name'] as String,
      sourceId: json['source_id'] as int,
      instaId: json['insta_id'] as String?,
      instaLogin: json['insta_login'] as String?,
      tgNick: json['tg_nick'] as String?,
      tgId: json['tg_id'] as String?,
      regionId: json['region_id'] as int?,
      birthday: json['birthday'] as String?,
      description: json['description'] as String?,
      leadStatusId: json['lead_status_id'] as int,
      position: json['position'] as int,
      managerId: json['manager_id'] as int?,
      waName: json['wa_name'] as String?,
      waPhone: json['wa_phone'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String,
      lead: json['lead'] as String?,
      email: json['email'] as String?,
      dialogState: json['dialog_state'] as String,
      organizationId: json['organization_id'] as int,
      sentTo1c: json['sent_to_1c'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      instagramPlatformIdId: json['instagram_platform_id_id'] as int?,
      deletedAt: json['deleted_at'] as String?,
      authorId: json['author_id'] as int,
      processingSpeed: json['processing_speed'] as int,
      isClient: json['is_client'] as int,
      messageStatus: json['messageStatus'] as String,
      firstResponseAt: json['first_response_at'] as String?,
      shamId: json['sham_id'] as String?,
      priceTypeId: json['price_type_id'] as int?,
      verificationCode: json['verification_code'] as String?,
      phoneVerifiedAt: json['phone_verified_at'] as String?,
      bonus: json['bonus'] as String,
      salesFunnelId: json['sales_funnel_id'] as int,
      activeScenarioExecutionId: json['active_scenario_execution_id'] as int?,
      tiktokCommenterId: json['tiktok_commenter_id'] as int?,
      token: json['token'] as String?,
    );
  }
}

