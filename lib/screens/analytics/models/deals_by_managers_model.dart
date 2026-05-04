import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

class ManagerDealsStats {
  final String managerName;
  final int totalDeals;
  final int successfulDeals;
  final double totalSum;
  final double successfulSum;

  ManagerDealsStats({
    required this.managerName,
    required this.totalDeals,
    required this.successfulDeals,
    required this.totalSum,
    required this.successfulSum,
  });

  factory ManagerDealsStats.fromJson(Map<String, dynamic> json) {
    return ManagerDealsStats(
      managerName: SafeConverters.toSafeString(json['manager_name']),
      totalDeals: SafeConverters.toInt(json['total_deals']),
      successfulDeals: SafeConverters.toInt(json['successful_deals']),
      totalSum: SafeConverters.toDouble(json['total_sum']),
      successfulSum: SafeConverters.toDouble(json['successful_sum']),
    );
  }
}

/// Model for /api/v2/dashboard/deals-by-managers
class DealsByManagersResponse {
  final List<ManagerDealsStats> managers;
  final String bestManager;
  final double totalRevenue;
  final int totalManagers;

  DealsByManagersResponse({
    required this.managers,
    required this.bestManager,
    required this.totalRevenue,
    required this.totalManagers,
  });

  factory DealsByManagersResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      final managersRaw = result['managers'];
      final managers = managersRaw is List
          ? managersRaw.map((e) => ManagerDealsStats.fromJson(e)).toList()
          : <ManagerDealsStats>[];

      return DealsByManagersResponse(
        managers: managers,
        bestManager: SafeConverters.toSafeString(result['best_manager']),
        totalRevenue: SafeConverters.toDouble(result['total_revenue']),
        totalManagers: SafeConverters.toInt(result['total_managers']),
      );
    }

    return DealsByManagersResponse(
      managers: [],
      bestManager: '',
      totalRevenue: 0,
      totalManagers: 0,
    );
  }
}
