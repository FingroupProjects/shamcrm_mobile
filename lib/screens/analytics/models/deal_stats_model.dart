import 'package:crm_task_manager/screens/analytics/utils/safe_converters.dart';

/// Model for deal statistics from /api/dashboard/dealStats
/// Response: {result: {data: [{total_sum, successful_sum}]}} (12 months)
class DealStatsModel {
  final double totalSum;
  final double successfulSum;

  DealStatsModel({
    required this.totalSum,
    required this.successfulSum,
  });

  factory DealStatsModel.fromJson(Map<String, dynamic> json) {
    return DealStatsModel(
      totalSum: SafeConverters.toDouble(json['total_sum']),
      successfulSum: SafeConverters.toDouble(json['successful_sum']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_sum': totalSum,
      'successful_sum': successfulSum,
    };
  }
}

/// Response wrapper for deal stats
class DealStatsResponse {
  final List<DealStatsModel> monthlyData;

  DealStatsResponse({required this.monthlyData});

  factory DealStatsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['result']?['data'];

    if (data is List) {
      return DealStatsResponse(
        monthlyData: data.map((e) => DealStatsModel.fromJson(e)).toList(),
      );
    }

    // Return 12 months of empty data if parsing fails
    return DealStatsResponse(
      monthlyData: List.generate(
        12,
        (_) => DealStatsModel(totalSum: 0, successfulSum: 0),
      ),
    );
  }
}
