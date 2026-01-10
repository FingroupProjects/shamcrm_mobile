class ActOfReconciliationResponse {
  final List<ReconciliationItem>? result;
  final String? errors;

  ActOfReconciliationResponse({
    this.result,
    this.errors,
  });

  factory ActOfReconciliationResponse.fromJson(Map<String, dynamic> json) {
    return ActOfReconciliationResponse(
      result: json['result'] != null
          ? (json['result'] as List)
          .map((e) => ReconciliationItem.fromJson(e))
          .toList()
          : null,
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result?.map((e) => e.toJson()).toList(),
      'errors': errors,
    };
  }
}

class ReconciliationItem {
  final int? id;
  final String? movementType;
  final String? saleSum;
  final String? sum;
  final DateTime? date;
  final String? modelType;
  final int? modelId;
  final String? organizationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? counterpartyType;
  final int? counterpartyId;
  final Counterparty? counterparty;
  final ModelData? model;

  ReconciliationItem({
    this.id,
    this.movementType,
    this.saleSum,
    this.sum,
    this.date,
    this.modelType,
    this.modelId,
    this.organizationId,
    this.createdAt,
    this.updatedAt,
    this.counterpartyType,
    this.counterpartyId,
    this.counterparty,
    this.model,
  });

  factory ReconciliationItem.fromJson(Map<String, dynamic> json) {
    return ReconciliationItem(
      id: json['id'],
      movementType: json['movement_type'],
      saleSum: json['sale_sum']?.toString(),
      sum: json['sum']?.toString(),
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      modelType: json['model_type'],
      modelId: json['model_id'],
      organizationId: json['organization_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      counterpartyType: json['counterparty_type'],
      counterpartyId: json['counterparty_id'],
      counterparty: json['counterparty'] != null
          ? Counterparty.fromJson(json['counterparty'])
          : null,
      model:
      json['model'] != null ? ModelData.fromJson(json['model']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movement_type': movementType,
      'sale_sum': saleSum,
      'sum': sum,
      'date': date?.toIso8601String(),
      'model_type': modelType,
      'model_id': modelId,
      'organization_id': organizationId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'counterparty_type': counterpartyType,
      'counterparty_id': counterpartyId,
      'counterparty': counterparty?.toJson(),
      'model': model?.toJson(),
    };
  }
}

class Counterparty {
  final int? id;
  final String? name;
  final String? phone;
  final String? email;
  final String? tgNick;
  final String? waPhone;
  final int? leadStatusId;
  final int? managerId;
  final int? organizationId;

  Counterparty({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.tgNick,
    this.waPhone,
    this.leadStatusId,
    this.managerId,
    this.organizationId,
  });

  factory Counterparty.fromJson(Map<String, dynamic> json) {
    return Counterparty(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      tgNick: json['tg_nick'],
      waPhone: json['wa_phone'],
      leadStatusId: json['lead_status_id'],
      managerId: json['manager_id'],
      organizationId: json['organization_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'tg_nick': tgNick,
      'wa_phone': waPhone,
      'lead_status_id': leadStatusId,
      'manager_id': managerId,
      'organization_id': organizationId,
    };
  }
}

class ModelData {
  final int? id;
  final String? counterpartyType;
  final int? counterpartyId;
  final String? ourDuty;
  final String? debtToUs;
  final int? counterpartySettlementId;
  final int? organizationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ModelData({
    this.id,
    this.counterpartyType,
    this.counterpartyId,
    this.ourDuty,
    this.debtToUs,
    this.counterpartySettlementId,
    this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  factory ModelData.fromJson(Map<String, dynamic> json) {
    return ModelData(
      id: json['id'],
      counterpartyType: json['counterparty_type'],
      counterpartyId: json['counterparty_id'],
      ourDuty: json['our_duty']?.toString(),
      debtToUs: json['debt_to_us']?.toString(),
      counterpartySettlementId: json['counterparty_settlement_id'],
      organizationId: json['organization_id'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'counterparty_type': counterpartyType,
      'counterparty_id': counterpartyId,
      'our_duty': ourDuty,
      'debt_to_us': debtToUs,
      'counterparty_settlement_id': counterpartySettlementId,
      'organization_id': organizationId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
