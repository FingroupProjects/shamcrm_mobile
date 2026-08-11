import 'package:crm_task_manager/utils/safe_converters.dart';

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
      batch: SafeConverters.toSafeString(json['batch']),
      price: SafeConverters.toSafeString(json['price']),
      date: SafeConverters.toSafeString(json['date']),
      quantity: SafeConverters.toInt(json['quantity']),
    );
  }

  Map<String, dynamic> toJson() => {
    'batch': batch,
    'price': price,
    'date': date,
    'quantity': quantity,
  };
}
