import 'package:crm_task_manager/models/page_2/dashboard/dashboard_goods_report.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:intl/intl.dart';

/// Ответ отчёта «Товары по сроку годности».
class ResultGoodsExpirationReport {
  final List<GoodsExpirationItem> data;
  final Pagination pagination;

  ResultGoodsExpirationReport({
    required this.data,
    required this.pagination,
  });

  factory ResultGoodsExpirationReport.fromJson(Map<String, dynamic> json) {
    return ResultGoodsExpirationReport(
      data: SafeConverters.toList(json['data'])
          .map(
            (item) => GoodsExpirationItem.fromJson(SafeConverters.toMap(item)),
          )
          .toList(),
      pagination: Pagination.fromJson(SafeConverters.toMap(json['pagination'])),
    );
  }
}

/// Одна строка отчёта. Карточка без перехода в детали.
class GoodsExpirationItem {
  final int id;
  final int? goodVariantId;
  final String name;
  final String category;
  final String storage;
  final String expirationDate;
  final int daysLeft;
  final String quantity;
  final String unit;

  GoodsExpirationItem({
    required this.id,
    this.goodVariantId,
    required this.name,
    required this.category,
    required this.storage,
    required this.expirationDate,
    required this.daysLeft,
    required this.quantity,
    required this.unit,
  });

  factory GoodsExpirationItem.fromJson(Map<String, dynamic> json) {
    return GoodsExpirationItem(
      id: SafeConverters.toInt(json['id']),
      goodVariantId: SafeConverters.toIntOrNull(json['good_variant_id']),
      name: SafeConverters.toSafeString(json['name']),
      category: SafeConverters.toSafeString(json['category']),
      storage: SafeConverters.toSafeString(json['storage']),
      expirationDate: SafeConverters.toSafeString(json['expiration_date']),
      daysLeft: SafeConverters.toInt(json['days_left']),
      quantity: _formatQuantity(json['quantity']),
      unit: SafeConverters.toSafeString(json['unit']),
    );
  }

  /// Дата для карточки: 12.09.2026
  String get formattedExpirationDate {
    try {
      return DateFormat('dd.MM.yyyy').format(DateTime.parse(expirationDate));
    } catch (_) {
      return expirationDate;
    }
  }

  /// Текст «дней осталось»: -7, 0, +2
  String get daysLeftLabel {
    if (daysLeft > 0) return '+$daysLeft';
    return '$daysLeft';
  }

  static String _formatQuantity(dynamic value) {
    if (value == null) return '0';
    if (value is int) return value.toString();
    if (value is double) {
      return value % 1 == 0
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
    }
    return value.toString();
  }
}
