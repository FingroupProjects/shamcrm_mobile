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

  factory DashboardGoodsMovementHistory.fromJson(Map<String, dynamic> json) {
    return DashboardGoodsMovementHistory(
      goodName: json['good_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: json['price'] ?? '0.00',
      storage: json['storage'] ?? '',
      date: DateTime.parse(json['date']),
      counterparty: json['counterparty'],
      counterpartyType: json['counterparty_type'],
      movementType: json['movement_type'] ?? '',
      documentType: json['document_type'],
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