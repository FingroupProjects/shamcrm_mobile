import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';

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
    final usersJson = json['users'];
    return SalesPlanDashboardItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      percent: json['percent'] is num
          ? (json['percent'] as num).toDouble()
          : double.tryParse('${json['percent'] ?? 0}') ?? 0,
      status: SalesPlanStatus.fromString(json['status']?.toString()),
      users: usersJson is List
          ? usersJson
              .whereType<Map>()
              .map((e) => SalesPlanUser.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
