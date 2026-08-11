import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

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
      userId: SafeConverters.toInt(json['user_id']),
      userName: SafeConverters.toSafeString(json['user_name']),
      planName: SafeConverters.toSafeString(json['plan_name']),
      planId: SafeConverters.toInt(json['plan_id']),
      targetValue: SafeConverters.toDouble(json['target_value']),
      actualValue: SafeConverters.toDouble(json['actual_value']),
      percent: SafeConverters.toDouble(json['percent']),
      status: SalesPlanStatus.fromString(SafeConverters.toStringOrNull(json['status'])),
    );
  }
}
