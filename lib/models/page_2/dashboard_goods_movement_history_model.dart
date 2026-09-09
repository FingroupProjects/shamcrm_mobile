import 'package:crm_task_manager/utils/safe_converters.dart';

class DashboardGoodsMovementHistory {
  final String goodName;
  final int quantity;
  final String price;
  final String storage;
  final DateTime date;
  final String? counterparty;
  final String? counterpartyType;
  final String movementType;
  final String? documentType;

  DashboardGoodsMovementHistory({
    required this.goodName,
    required this.quantity,
    required this.price,
    required this.storage,
    required this.date,
    this.counterparty,
    this.counterpartyType,
    required this.movementType,
    this.documentType,
  });

  factory DashboardGoodsMovementHistory.fromJson(dynamic json) {
    final map = SafeConverters.toMap(json);
    final counterpartyRaw = map['counterparty'];
    String? counterpartyName;
    if (counterpartyRaw is Map) {
      final counterpartyMap = SafeConverters.toMap(counterpartyRaw);
      counterpartyName = SafeConverters.toStringOrNull(
        counterpartyMap['name'] ?? counterpartyMap['title'],
      );
    } else {
      counterpartyName = SafeConverters.toStringOrNull(counterpartyRaw);
    }

    return DashboardGoodsMovementHistory(
      goodName: SafeConverters.toSafeString(map['good_name']),
      quantity: SafeConverters.toInt(map['quantity']),
      price: SafeConverters.toSafeString(map['price'], defaultValue: '0.00'),
      storage: SafeConverters.toSafeString(map['storage']),
      date: SafeConverters.toDateTime(map['date']),
      counterparty: counterpartyName,
      counterpartyType: SafeConverters.toStringOrNull(map['counterparty_type']),
      movementType: SafeConverters.toSafeString(map['movement_type']),
      documentType: SafeConverters.toStringOrNull(map['document_type']),
    );
  }

  Map<String, dynamic> toJson() => {
        'good_name': goodName,
        'quantity': quantity,
        'price': price,
        'storage': storage,
        'date': date.toIso8601String(),
        'counterparty': counterparty,
        'counterparty_type': counterpartyType,
        'movement_type': movementType,
        'document_type': documentType,
      };
}
