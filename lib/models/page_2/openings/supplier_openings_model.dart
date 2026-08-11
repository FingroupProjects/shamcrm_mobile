import 'package:crm_task_manager/utils/safe_converters.dart';

class SupplierOpeningsResponse {
  final List<SupplierOpening>? result;
  final dynamic errors;

  SupplierOpeningsResponse({
    this.result,
    this.errors,
  });

  factory SupplierOpeningsResponse.fromJson(Map<String, dynamic> json) {
    if (json["result"] != null) {
      final resultData = json["result"];
      if (resultData is Map<String, dynamic> && resultData["data"] != null) {
        // Формат: {"result": {"data": [...]}}
        return SupplierOpeningsResponse(
          result: SafeConverters.toList(resultData["data"])
              .whereType<Map<String, dynamic>>()
              .map((x) => SupplierOpening.fromJson(x))
              .toList(),
          errors: json["errors"],
        );
      } else if (resultData is List) {
        // Формат: {"result": [...]}
    return SupplierOpeningsResponse(
          result: resultData
              .whereType<Map<String, dynamic>>()
              .map((x) => SupplierOpening.fromJson(x))
              .toList(),
      errors: json["errors"],
    );
      }
    }
    return SupplierOpeningsResponse(result: [], errors: json["errors"]);
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
      id: SafeConverters.toIntOrNull(json['id']),
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
          : SupplierCounterparty.fromJson(
              SafeConverters.toMap(json['counterparty'])),
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
      id: SafeConverters.toIntOrNull(json['id']),
      name: SafeConverters.toStringOrNull(json['name']),
      phone: SafeConverters.toStringOrNull(json['phone']),
      inn: SafeConverters.toIntOrNull(json['inn']),
      note: SafeConverters.toStringOrNull(json['note']),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

