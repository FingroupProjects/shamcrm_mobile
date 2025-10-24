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
  final int? id;
  final String? counterpartyType;
  final int? counterpartyId;
  final String? ourDuty;
  final String? debtToUs;
  final int? counterpartySettlementId;
  final int? organizationId;
  final String? createdAt;
  final String? updatedAt;
  final SupplierCounterparty? counterparty;

  SupplierOpening({
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

  factory SupplierOpening.fromJson(Map<String, dynamic> json) {
    return SupplierOpening(
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
          : SupplierCounterparty.fromJson(json['counterparty'] as Map<String, dynamic>),
    );
  }
}

class SupplierCounterparty {
  final int? id;
  final String? name;
  final String? phone;
  final int? inn;
  final String? note;
  final String? createdAt;
  final String? updatedAt;

  SupplierCounterparty({
    this.id,
    this.name,
    this.phone,
    this.inn,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory SupplierCounterparty.fromJson(Map<String, dynamic> json) {
    return SupplierCounterparty(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      inn: json['inn'],
      note: json['note'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

