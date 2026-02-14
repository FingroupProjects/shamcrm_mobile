import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

class StatValue {
  final double count;
  final double percent;

  StatValue({
    required this.count,
    required this.percent,
  });

  factory StatValue.fromJson(Map<String, dynamic> json) {
    return StatValue(
      count: SafeConverters.toDouble(json['count']),
      percent: SafeConverters.toDouble(json['procent']),
    );
  }
}

/// Model for /api/v2/dashboard/statistics
class DashboardStatisticsResponse {
  final StatValue leads;
  final StatValue deals;
  final StatValue totalSum;
  final StatValue conversion;

  DashboardStatisticsResponse({
    required this.leads,
    required this.deals,
    required this.totalSum,
    required this.conversion,
  });

  factory DashboardStatisticsResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      return DashboardStatisticsResponse(
        leads: StatValue.fromJson(
            (result['leads'] as Map<String, dynamic>? ?? {})),
        deals: StatValue.fromJson(
            (result['deals'] as Map<String, dynamic>? ?? {})),
        totalSum: StatValue.fromJson(
            (result['totalSum'] as Map<String, dynamic>? ?? {})),
        conversion: StatValue.fromJson(
            (result['conversion'] as Map<String, dynamic>? ?? {})),
      );
    }

    return DashboardStatisticsResponse(
      leads: StatValue(count: 0, percent: 0),
      deals: StatValue(count: 0, percent: 0),
      totalSum: StatValue(count: 0, percent: 0),
      conversion: StatValue(count: 0, percent: 0),
    );
  }
}
