import 'package:crm_task_manager/utils/safe_converters.dart';

class TopSellingCardModel {
  /*
  response: result.data:
  "id": 2,
"name": "Футболки 4455",
"category": "Игровые ПК",
"total_quantity": 220,
"total_amount": "450.00",
"avg_price": "2.000000"
   */
  final int id;
  final String name;
  final String category;
  final num totalQuantity;
  final String totalAmount;
  final String avgPrice;

  TopSellingCardModel({
    required this.id,
    required this.name,
    required this.category,
    required this.totalQuantity,
    required this.totalAmount,
    required this.avgPrice,
  });

  // from json and to json methods
  factory TopSellingCardModel.fromJson(Map<String, dynamic> json) {
    return TopSellingCardModel(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      category: SafeConverters.toSafeString(json['category']),
      totalQuantity: SafeConverters.toNum(json['total_quantity']),
      totalAmount: SafeConverters.toSafeString(json['total_amount']),
      avgPrice: SafeConverters.toSafeString(json['avg_price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'total_quantity': totalQuantity,
      'total_amount': totalAmount,
      'avg_price': avgPrice,
    };
  }
}
