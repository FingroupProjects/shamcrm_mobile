import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

class TopProductSummary {
  final String name;
  final int sales;
  final double revenue;
  final String revenueFormatted;

  TopProductSummary({
    required this.name,
    required this.sales,
    required this.revenue,
    required this.revenueFormatted,
  });

  factory TopProductSummary.fromJson(Map<String, dynamic> json) {
    return TopProductSummary(
      name: SafeConverters.toSafeString(json['name']),
      sales: SafeConverters.toInt(json['sales']),
      revenue: SafeConverters.toDouble(json['revenue']),
      revenueFormatted:
          SafeConverters.toSafeString(json['revenue_formatted']),
    );
  }
}

class TopSellingProductItem {
  final int goodId;
  final String name;
  final int totalSold;
  final int successful;
  final int cancelled;
  final double conversion;
  final double revenue;
  final String revenueFormatted;

  TopSellingProductItem({
    required this.goodId,
    required this.name,
    required this.totalSold,
    required this.successful,
    required this.cancelled,
    required this.conversion,
    required this.revenue,
    required this.revenueFormatted,
  });

  factory TopSellingProductItem.fromJson(Map<String, dynamic> json) {
    return TopSellingProductItem(
      goodId: SafeConverters.toInt(json['good_id']),
      name: SafeConverters.toSafeString(json['name']),
      totalSold: SafeConverters.toInt(json['total_sold']),
      successful: SafeConverters.toInt(json['successful']),
      cancelled: SafeConverters.toInt(json['cancelled']),
      conversion: SafeConverters.toDouble(json['conversion']),
      revenue: SafeConverters.toDouble(json['revenue']),
      revenueFormatted:
          SafeConverters.toSafeString(json['revenue_formatted']),
    );
  }
}

/// Model for /api/v2/dashboard/top-selling-products-chart
class TopSellingProductsResponse {
  final TopProductSummary top;
  final List<TopSellingProductItem> list;

  TopSellingProductsResponse({
    required this.top,
    required this.list,
  });

  factory TopSellingProductsResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      final topRaw = result['top'] as Map<String, dynamic>? ?? {};
      final listRaw = result['list'];
      final list = listRaw is List
          ? listRaw.map((e) => TopSellingProductItem.fromJson(e)).toList()
          : <TopSellingProductItem>[];

      return TopSellingProductsResponse(
        top: TopProductSummary.fromJson(topRaw),
        list: list,
      );
    }

    return TopSellingProductsResponse(
      top: TopProductSummary(
        name: '',
        sales: 0,
        revenue: 0,
        revenueFormatted: '',
      ),
      list: [],
    );
  }
}
