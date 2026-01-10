import 'package:crm_task_manager/models/page_2/order_card.dart';

class OrderGoodVariant {
  final int id;
  final int? variantId;
  final int? orderId;
  final int quantity;
  final String price;
  final Map<String, dynamic>? variant;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderGoodVariant({
    required this.id,
    this.variantId,
    this.orderId,
    required this.quantity,
    required this.price,
    this.variant,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderGoodVariant.fromJson(Map<String, dynamic> json) {
    return OrderGoodVariant(
      id: json['id'] ?? 0,
      variantId: json['variant_id'] != null ? int.tryParse(json['variant_id'].toString()) : null,
      orderId: json['order_id'] != null ? int.tryParse(json['order_id'].toString()) : null,
      quantity: json['quantity'] ?? 0,
      price: json['price']?.toString() ?? '0',
      variant: json['variant'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'variant_id': variantId,
      'order_id': orderId,
      'quantity': quantity,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'price': price,
      'variant': variant != null
          ? {
              'id': variantId,
              'good_id': variant?['good_id'],
              'is_active': variant?['is_active'],
              'created_at': variant?['created_at'],
              'updated_at': variant?['updated_at'],
              'attribute_values': variant?['attribute_values'],
              'good': variant?['good'] != null
                  ? {
                      'id': variant?['good']['id'],
                      'name': variant?['good']['name'],
                      'files': (variant?['good']['files'] as List<dynamic>?)?.map((f) => {
                            'id': f['id'],
                            'name': f['name'],
                            'path': f['path'],
                            'model_type': f['model_type'],
                            'model_id': f['model_id'],
                            'created_at': f['created_at'],
                            'updated_at': f['updated_at'],
                            'external_id': f['external_id'],
                            'external_url': f['external_url'],
                            'is_main': f['is_main'],
                          }).toList(),
                    }
                  : null,
              'price': variant?['price'],
            }
          : null,
      'good': null,
    };
  }
}