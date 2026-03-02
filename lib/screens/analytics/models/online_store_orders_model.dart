import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

class OrdersChartPoint {
  final int month;
  final int totalOrders;
  final int successfulOrders;
  final int canceledOrders;

  OrdersChartPoint({
    required this.month,
    required this.totalOrders,
    required this.successfulOrders,
    required this.canceledOrders,
  });

  factory OrdersChartPoint.fromJson(Map<String, dynamic> json) {
    return OrdersChartPoint(
      month: SafeConverters.toInt(json['month']),
      totalOrders: SafeConverters.toInt(json['total_orders']),
      successfulOrders: SafeConverters.toInt(json['successful_orders']),
      canceledOrders: SafeConverters.toInt(json['canceled_orders']),
    );
  }
}

/// Model for /api/v2/dashboard/online-store-orders-chart
class OnlineStoreOrdersResponse {
  final int totalOrders;
  final int successfulOrders;
  final double successRate;
  final double averageCheck;
  final double revenue;
  final List<OrdersChartPoint> chartData;

  OnlineStoreOrdersResponse({
    required this.totalOrders,
    required this.successfulOrders,
    required this.successRate,
    required this.averageCheck,
    required this.revenue,
    required this.chartData,
  });

  factory OnlineStoreOrdersResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      final chartDataRaw = result['chart_data'];
      final chartData = chartDataRaw is List
          ? chartDataRaw.map((e) => OrdersChartPoint.fromJson(e)).toList()
          : <OrdersChartPoint>[];

      return OnlineStoreOrdersResponse(
        totalOrders: SafeConverters.toInt(result['total_orders']),
        successfulOrders: SafeConverters.toInt(result['successful_orders']),
        successRate: SafeConverters.toDouble(result['success_rate']),
        averageCheck: SafeConverters.toDouble(result['average_check']),
        revenue: SafeConverters.toDouble(result['revenue']),
        chartData: chartData,
      );
    }

    return OnlineStoreOrdersResponse(
      totalOrders: 0,
      successfulOrders: 0,
      successRate: 0,
      averageCheck: 0,
      revenue: 0,
      chartData: [],
    );
  }
}
