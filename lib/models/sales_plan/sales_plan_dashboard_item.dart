import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';

class SalesPlanDashboardItem {
  final int id;
  final String name;
  final double percent;
  final SalesPlanStatus status;
  final List<SalesPlanUser> users;

  SalesPlanDashboardItem({
    required this.id,
    required this.name,
    required this.percent,
    required this.status,
    this.users = const [],
  });

  factory SalesPlanDashboardItem.fromJson(Map<String, dynamic> json) {
    return SalesPlanDashboardItem(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      percent: SafeConverters.toDouble(json['percent']),
      status: SalesPlanStatus.fromString(SafeConverters.toStringOrNull(json['status'])),
      users: SafeConverters.toList(json['users'])
          .map((e) => SalesPlanUser.fromJson(SafeConverters.toMap(e)))
          .toList(),
    );
  }
}
