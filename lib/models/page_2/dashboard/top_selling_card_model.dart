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
      id: json['id'] as int,
      name: json['name'].toString(),
      category: json['category'].toString(),
      totalQuantity: json['total_quantity'] as num,
      totalAmount: json['total_amount'].toString(),
      avgPrice: json['avg_price'].toString(),
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