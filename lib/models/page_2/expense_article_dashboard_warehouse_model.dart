import 'package:crm_task_manager/utils/safe_converters.dart';

// ============================================
// expense_article_dashboard_warehouse_model.dart
// ============================================
class ExpenseArticleDashboardWarehouse {
  final int id;
  final String name;
  final String type;

  ExpenseArticleDashboardWarehouse({
    required this.id,
    required this.name,
    required this.type,
  });

  factory ExpenseArticleDashboardWarehouse.fromJson(Map<String, dynamic> json) {
    return ExpenseArticleDashboardWarehouse(
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      type: SafeConverters.toSafeString(json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseArticleDashboardWarehouse &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
