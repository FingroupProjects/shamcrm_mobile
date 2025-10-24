class SupplierOpeningsResponse {
  final List<SupplierOpening>? result;
  final dynamic errors;

  SupplierOpeningsResponse({
    this.result,
    this.errors,
  });

  factory SupplierOpeningsResponse.fromJson(Map<String, dynamic> json) {
    return SupplierOpeningsResponse(
      result: json["result"] == null
          ? []
          : List<SupplierOpening>.from(
              json["result"]!.map((x) => SupplierOpening.fromJson(x))),
      errors: json["errors"],
    );
  }
}

class SupplierOpening {
  final int id;
  final String counterpartyType;
  final int counterpartyId;
  final String ourDuty;
  final String debtToUs;
  final int? counterpartySettlementId;
  final int organizationId;
  final String createdAt;
  final String updatedAt;
  final SupplierCounterparty counterparty;

  SupplierOpening({
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

  factory SupplierOpening.fromJson(Map<String, dynamic> json) {
    return SupplierOpening(
      id: json['id'] as int,
      counterpartyType: json['counterparty_type'] as String,
      counterpartyId: json['counterparty_id'] as int,
      ourDuty: json['our_duty'] as String,
      debtToUs: json['debt_to_us'] as String,
      counterpartySettlementId: json['counterparty_settlement_id'] as int?,
      organizationId: json['organization_id'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      counterparty: SupplierCounterparty.fromJson(json['counterparty'] as Map<String, dynamic>),
    );
  }
}

class SupplierCounterparty {
  final int id;
  final String name;
  final String phone;
  final int inn;
  final String note;
  final String createdAt;
  final String updatedAt;

  SupplierCounterparty({
    required this.id,
    required this.name,
    required this.phone,
    required this.inn,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierCounterparty.fromJson(Map<String, dynamic> json) {
    return SupplierCounterparty(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      inn: json['inn'] as int,
      note: json['note'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

