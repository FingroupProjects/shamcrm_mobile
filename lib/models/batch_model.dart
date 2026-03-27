class BatchData {
  final String batch;
  final String price;
  final String date;
  final int quantity;

  BatchData({
    required this.batch,
    required this.price,
    required this.date,
    required this.quantity,
  });

  factory BatchData.fromJson(Map<String, dynamic> json) {
    return BatchData(
      batch: json['batch'] as String,
      price: json['price'] as String,
      date: json['date'] as String,
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'batch': batch,
    'price': price,
    'date': date,
    'quantity': quantity,
  };
}