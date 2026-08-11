import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';

class SalesPlanLeaderboardItem {
  final int userId;
  final String userName;
  final String planName;
  final int planId;
  final double targetValue;
  final double actualValue;
  final double percent;
  final SalesPlanStatus status;

  SalesPlanLeaderboardItem({
    required this.userId,
    required this.userName,
    required this.planName,
    required this.planId,
    required this.targetValue,
    required this.actualValue,
    required this.percent,
    required this.status,
  });

  factory SalesPlanLeaderboardItem.fromJson(Map<String, dynamic> json) {
    return SalesPlanLeaderboardItem(
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse('${json['user_id']}') ?? 0,
      userName: json['user_name']?.toString() ?? '',
      planName: json['plan_name']?.toString() ?? '',
      planId: json['plan_id'] is int
          ? json['plan_id'] as int
          : int.tryParse('${json['plan_id']}') ?? 0,
      targetValue: json['target_value'] is num
          ? (json['target_value'] as num).toDouble()
          : double.tryParse('${json['target_value'] ?? 0}') ?? 0,
      actualValue: json['actual_value'] is num
          ? (json['actual_value'] as num).toDouble()
          : double.tryParse('${json['actual_value'] ?? 0}') ?? 0,
      percent: json['percent'] is num
          ? (json['percent'] as num).toDouble()
          : double.tryParse('${json['percent'] ?? 0}') ?? 0,
      status: SalesPlanStatus.fromString(json['status']?.toString()),
    );
  }
}
