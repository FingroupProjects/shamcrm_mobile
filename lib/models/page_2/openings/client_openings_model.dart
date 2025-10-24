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
  final int? id;
  final String? counterpartyType;
  final int? counterpartyId;
  final String? ourDuty;
  final String? debtToUs;
  final int? counterpartySettlementId;
  final int? organizationId;
  final String? createdAt;
  final String? updatedAt;
  final ClientCounterparty? counterparty;

  ClientOpening({
    this.id,
    this.counterpartyType,
    this.counterpartyId,
    this.ourDuty,
    this.debtToUs,
    this.counterpartySettlementId,
    this.organizationId,
    this.createdAt,
    this.updatedAt,
    this.counterparty,
  });

  factory ClientOpening.fromJson(Map<String, dynamic> json) {
    return ClientOpening(
      id: json['id'],
      counterpartyType: json['counterparty_type'],
      counterpartyId: json['counterparty_id'],
      ourDuty: json['our_duty'],
      debtToUs: json['debt_to_us'],
      counterpartySettlementId: json['counterparty_settlement_id'],
      organizationId: json['organization_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      counterparty: json['counterparty'] == null
          ? null
          : ClientCounterparty.fromJson(json['counterparty'] as Map<String, dynamic>),
    );
  }
}

class ClientCounterparty {
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
  final int? position;
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
  final String? createdAt;
  final String? updatedAt;
  final int? instagramPlatformIdId;
  final String? deletedAt;
  final int? authorId;
  final int? processingSpeed;
  final int? isClient;
  final String? messageStatus;
  final String? firstResponseAt;
  final String? shamId;
  final int? priceTypeId;
  final String? verificationCode;
  final String? phoneVerifiedAt;
  final String? bonus;
  final int? salesFunnelId;
  final int? activeScenarioExecutionId;
  final int? tiktokCommenterId;
  final String? token;

  ClientCounterparty({
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

  factory ClientCounterparty.fromJson(Map<String, dynamic> json) {
    return ClientCounterparty(
      id: json['id'],
      leadId: json['lead_id'],
      name: json['name'],
      sourceId: json['source_id'],
      instaId: json['insta_id'],
      instaLogin: json['insta_login'],
      tgNick: json['tg_nick'],
      tgId: json['tg_id'],
      regionId: json['region_id'],
      birthday: json['birthday'],
      description: json['description'],
      leadStatusId: json['lead_status_id'],
      position: json['position'],
      managerId: json['manager_id'],
      waName: json['wa_name'],
      waPhone: json['wa_phone'],
      address: json['address'],
      phone: json['phone'],
      lead: json['lead'],
      email: json['email'],
      dialogState: json['dialog_state'],
      organizationId: json['organization_id'],
      sentTo1c: json['sent_to_1c'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      instagramPlatformIdId: json['instagram_platform_id_id'],
      deletedAt: json['deleted_at'],
      authorId: json['author_id'],
      processingSpeed: json['processing_speed'],
      isClient: json['is_client'],
      messageStatus: json['messageStatus'],
      firstResponseAt: json['first_response_at'],
      shamId: json['sham_id'],
      priceTypeId: json['price_type_id'],
      verificationCode: json['verification_code'],
      phoneVerifiedAt: json['phone_verified_at'],
      bonus: json['bonus'],
      salesFunnelId: json['sales_funnel_id'],
      activeScenarioExecutionId: json['active_scenario_execution_id'],
      tiktokCommenterId: json['tiktok_commenter_id'],
      token: json['token'],
    );
  }
}