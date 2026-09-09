import 'package:crm_task_manager/utils/safe_converters.dart';

class ActOfReconciliationResponse {
  final List<ReconciliationItem>? result;
  final String? errors;

  ActOfReconciliationResponse({
    this.result,
    this.errors,
  });

  factory ActOfReconciliationResponse.fromJson(dynamic json) {
    final map = SafeConverters.toMap(json);
    return ActOfReconciliationResponse(
      result: _parseItems(map['result']),
      errors: SafeConverters.toStringOrNull(map['errors']),
    );
  }

  static List<ReconciliationItem>? _parseItems(dynamic raw) {
    if (raw == null) return null;

    final items = _extractItemList(raw);
    if (items == null) return const [];

    return SafeConverters.toModelList(items, ReconciliationItem.fromJson);
  }

  static List<dynamic>? _extractItemList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is String) {
      final decodedList = SafeConverters.toList(raw);
      if (decodedList.isNotEmpty) return decodedList;
      return null;
    }
    if (raw is! Map) return null;

    final map = SafeConverters.toMap(raw);
    for (final key in const [
      'data',
      'items',
      'movements',
      'documents',
      'result',
    ]) {
      final value = map[key];
      if (value is List) return value;
      final asList = SafeConverters.toList(value);
      if (asList.isNotEmpty) return asList;
    }

    if (map.containsKey('id') ||
        map.containsKey('movement_type') ||
        map.containsKey('operation_type')) {
      return [map];
    }

    return const [];
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

  factory ReconciliationItem.fromJson(dynamic json) {
    final map = SafeConverters.toMap(json);
    return ReconciliationItem(
      id: SafeConverters.toIntOrNull(map['id']),
      movementType: SafeConverters.toStringOrNull(map['movement_type']) ??
          SafeConverters.toStringOrNull(map['operation_type']) ??
          SafeConverters.toStringOrNull(map['document_type']),
      saleSum: SafeConverters.toStringOrNull(map['sale_sum']),
      sum: SafeConverters.toStringOrNull(map['sum']),
      date: SafeConverters.toDateTimeOrNull(map['date']),
      modelType: SafeConverters.toStringOrNull(map['model_type']),
      modelId: SafeConverters.toIntOrNull(map['model_id']),
      organizationId: SafeConverters.toStringOrNull(map['organization_id']),
      createdAt: SafeConverters.toDateTimeOrNull(map['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(map['updated_at']),
      counterpartyType: SafeConverters.toStringOrNull(map['counterparty_type']),
      counterpartyId: SafeConverters.toIntOrNull(map['counterparty_id']),
      counterparty: _parseCounterparty(map['counterparty']),
      model: SafeConverters.toModelOrNull(map['model'], ModelData.fromJson),
    );
  }

  static Counterparty? _parseCounterparty(dynamic raw) {
    final fromMap = SafeConverters.toModelOrNull(raw, Counterparty.fromJson);
    if (fromMap != null) return fromMap;
    if (raw is String && raw.trim().isNotEmpty) {
      return Counterparty(name: raw.trim());
    }
    if (raw is num) {
      return Counterparty(id: raw.toInt(), name: raw.toString());
    }
    return null;
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

  factory Counterparty.fromJson(dynamic json) {
    final map = SafeConverters.toMap(json);
    return Counterparty(
      id: SafeConverters.toIntOrNull(map['id']),
      name: SafeConverters.toStringOrNull(map['name']),
      phone: SafeConverters.toStringOrNull(map['phone']),
      email: SafeConverters.toStringOrNull(map['email']),
      tgNick: SafeConverters.toStringOrNull(map['tg_nick']),
      waPhone: SafeConverters.toStringOrNull(map['wa_phone']),
      leadStatusId: SafeConverters.toIntOrNull(map['lead_status_id']),
      managerId: SafeConverters.toIntOrNull(map['manager_id']),
      organizationId: SafeConverters.toIntOrNull(map['organization_id']),
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

  factory ModelData.fromJson(dynamic json) {
    final map = SafeConverters.toMap(json);
    return ModelData(
      id: SafeConverters.toIntOrNull(map['id']),
      counterpartyType: SafeConverters.toStringOrNull(map['counterparty_type']),
      counterpartyId: SafeConverters.toIntOrNull(map['counterparty_id']),
      ourDuty: SafeConverters.toStringOrNull(map['our_duty']),
      debtToUs: SafeConverters.toStringOrNull(map['debt_to_us']),
      counterpartySettlementId:
          SafeConverters.toIntOrNull(map['counterparty_settlement_id']),
      organizationId: SafeConverters.toIntOrNull(map['organization_id']),
      createdAt: SafeConverters.toDateTimeOrNull(map['created_at']),
      updatedAt: SafeConverters.toDateTimeOrNull(map['updated_at']),
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
