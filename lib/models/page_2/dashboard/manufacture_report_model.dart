import 'package:equatable/equatable.dart';

class ManufactureReportResponse extends Equatable {
  final List<ManufactureGoodsReportItem> data;
  final ManufactureReportPagination pagination;

  const ManufactureReportResponse({
    required this.data,
    required this.pagination,
  });

  factory ManufactureReportResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? json;

    return ManufactureReportResponse(
      data: (result['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ManufactureGoodsReportItem.fromJson)
          .toList(),
      pagination: ManufactureReportPagination.fromJson(
        result['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  @override
  List<Object?> get props => [data, pagination];
}

class ManufactureGoodsReportItem extends Equatable {
  final String date;
  final String document;
  final int goodId;
  final String good;
  final double quantity;
  final String unit;
  final double costPricePerUnit;
  final double totalCost;
  final int authorId;
  final String author;

  const ManufactureGoodsReportItem({
    required this.date,
    required this.document,
    required this.goodId,
    required this.good,
    required this.quantity,
    required this.unit,
    required this.costPricePerUnit,
    required this.totalCost,
    required this.authorId,
    required this.author,
  });

  factory ManufactureGoodsReportItem.fromJson(Map<String, dynamic> json) {
    return ManufactureGoodsReportItem(
      date: json['date']?.toString() ?? '',
      document: json['document']?.toString() ?? '',
      goodId: _asInt(json['good_id']),
      good: json['good']?.toString() ?? '',
      quantity: _asDouble(json['quantity']),
      unit: json['unit']?.toString() ?? '',
      costPricePerUnit: _asDouble(json['cost_price_per_unit']),
      totalCost: _asDouble(json['total_cost']),
      authorId: _asInt(json['author_id']),
      author: json['author']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        date,
        document,
        goodId,
        good,
        quantity,
        unit,
        costPricePerUnit,
        totalCost,
        authorId,
        author,
      ];
}

class ManufactureMaterialsReportResponse extends Equatable {
  final List<ManufactureMaterialsReportItem> data;
  final ManufactureReportPagination pagination;

  const ManufactureMaterialsReportResponse({
    required this.data,
    required this.pagination,
  });

  factory ManufactureMaterialsReportResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final result = json['result'] as Map<String, dynamic>? ?? json;

    return ManufactureMaterialsReportResponse(
      data: (result['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ManufactureMaterialsReportItem.fromJson)
          .toList(),
      pagination: ManufactureReportPagination.fromJson(
        result['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  @override
  List<Object?> get props => [data, pagination];
}

class ManufactureMaterialsReportItem extends Equatable {
  final int materialVariantId;
  final int materialGoodId;
  final String rawMaterial;
  final double quantityUsed;
  final String unit;
  final double price;
  final double sum;

  const ManufactureMaterialsReportItem({
    required this.materialVariantId,
    required this.materialGoodId,
    required this.rawMaterial,
    required this.quantityUsed,
    required this.unit,
    required this.price,
    required this.sum,
  });

  factory ManufactureMaterialsReportItem.fromJson(Map<String, dynamic> json) {
    return ManufactureMaterialsReportItem(
      materialVariantId: _asInt(json['material_variant_id']),
      materialGoodId: _asInt(json['material_good_id']),
      rawMaterial: json['raw_material']?.toString() ?? '',
      quantityUsed: _asDouble(json['quantity_used']),
      unit: json['unit']?.toString() ?? '',
      price: _asDouble(json['price']),
      sum: _asDouble(json['sum']),
    );
  }

  @override
  List<Object?> get props => [
        materialVariantId,
        materialGoodId,
        rawMaterial,
        quantityUsed,
        unit,
        price,
        sum,
      ];
}

class ManufactureReportPagination extends Equatable {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  const ManufactureReportPagination({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory ManufactureReportPagination.fromJson(Map<String, dynamic> json) {
    return ManufactureReportPagination(
      total: _asInt(json['total']),
      count: _asInt(json['count']),
      perPage: _asInt(json['per_page']),
      currentPage: _asInt(json['current_page']),
      totalPages: _asInt(json['total_pages']),
    );
  }

  @override
  List<Object?> get props => [total, count, perPage, currentPage, totalPages];
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
