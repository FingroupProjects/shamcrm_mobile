import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

class ManufactureReportResponse extends Equatable {
  final List<ManufactureGoodsReportItem> data;
  final ManufactureReportPagination pagination;

  const ManufactureReportResponse({
    required this.data,
    required this.pagination,
  });

  factory ManufactureReportResponse.fromJson(Map<String, dynamic> json) {
    final result = SafeConverters.toMapOrNull(json['result']) ?? json;

    return ManufactureReportResponse(
      data: SafeConverters.toList(result['data'])
          .whereType<Map<String, dynamic>>()
          .map(ManufactureGoodsReportItem.fromJson)
          .toList(),
      pagination: ManufactureReportPagination.fromJson(
        SafeConverters.toMap(result['pagination']),
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
      date: SafeConverters.toSafeString(json['date']),
      document: SafeConverters.toSafeString(json['document']),
      goodId: SafeConverters.toInt(json['good_id']),
      good: SafeConverters.toSafeString(json['good']),
      quantity: SafeConverters.toDouble(json['quantity']),
      unit: SafeConverters.toSafeString(json['unit']),
      costPricePerUnit: SafeConverters.toDouble(json['cost_price_per_unit']),
      totalCost: SafeConverters.toDouble(json['total_cost']),
      authorId: SafeConverters.toInt(json['author_id']),
      author: SafeConverters.toSafeString(json['author']),
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
    final result = SafeConverters.toMapOrNull(json['result']) ?? json;

    return ManufactureMaterialsReportResponse(
      data: SafeConverters.toList(result['data'])
          .whereType<Map<String, dynamic>>()
          .map(ManufactureMaterialsReportItem.fromJson)
          .toList(),
      pagination: ManufactureReportPagination.fromJson(
        SafeConverters.toMap(result['pagination']),
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
      materialVariantId: SafeConverters.toInt(json['material_variant_id']),
      materialGoodId: SafeConverters.toInt(json['material_good_id']),
      rawMaterial: SafeConverters.toSafeString(json['raw_material']),
      quantityUsed: SafeConverters.toDouble(json['quantity_used']),
      unit: SafeConverters.toSafeString(json['unit']),
      price: SafeConverters.toDouble(json['price']),
      sum: SafeConverters.toDouble(json['sum']),
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
      total: SafeConverters.toInt(json['total']),
      count: SafeConverters.toInt(json['count']),
      perPage: SafeConverters.toInt(json['per_page']),
      currentPage: SafeConverters.toInt(json['current_page']),
      totalPages: SafeConverters.toInt(json['total_pages']),
    );
  }

  @override
  List<Object?> get props => [total, count, perPage, currentPage, totalPages];
}
