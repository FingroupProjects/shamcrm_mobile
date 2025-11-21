class CashRegisterOpeningsResponse {
  final List<CashRegisterOpening>? result;
  final dynamic errors;

  CashRegisterOpeningsResponse({
    this.result,
    this.errors,
  });

  factory CashRegisterOpeningsResponse.fromJson(Map<String, dynamic> json) =>
      CashRegisterOpeningsResponse(
        result: json["result"] == null
            ? []
            : List<CashRegisterOpening>.from(
                json["result"]!.map((x) => CashRegisterOpening.fromJson(x))),
        errors: json["errors"],
      );

  Map<String, dynamic> toJson() => {
        "result": result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toJson())),
        "errors": errors,
      };
}

class CashRegisterOpening {
  final int? id;
  final int? cashRegisterId;
  final String? sum;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? cashId;
  final CashRegister? cashRegister;

  CashRegisterOpening({
    this.id,
    this.cashRegisterId,
    this.sum,
    this.createdAt,
    this.updatedAt,
    this.cashId,
    this.cashRegister,
  });

  factory CashRegisterOpening.fromJson(Map<String, dynamic> json) =>
      CashRegisterOpening(
        id: json["id"],
        cashRegisterId: json["cash_register_id"],
        sum: json["sum"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        cashId: json["cash_id"],
        cashRegister: json["cash_register"] == null
            ? null
            : CashRegister.fromJson(json["cash_register"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "cash_register_id": cashRegisterId,
        "sum": sum,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "cash_id": cashId,
        "cash_register": cashRegister?.toJson(),
      };
}

class CashRegister {
  final int? id;
  final String? name;
  final int? organizationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CashRegister({
    this.id,
    this.name,
    this.organizationId,
    this.createdAt,
    this.updatedAt,
  });

  factory CashRegister.fromJson(Map<String, dynamic> json) => CashRegister(
        id: json["id"],
        name: json["name"],
        organizationId: json["organization_id"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "organization_id": organizationId,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}
