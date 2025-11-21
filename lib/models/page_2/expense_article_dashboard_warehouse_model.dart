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
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
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
