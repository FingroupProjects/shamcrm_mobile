// ============================================
// expense_article_dashboard_warehouse_state.dart
// ============================================
import 'package:crm_task_manager/models/page_2/expense_article_dashboard_warehouse_model.dart';

abstract class ExpenseArticleDashboardWarehouseState {}

class ExpenseArticleDashboardWarehouseInitial extends ExpenseArticleDashboardWarehouseState {}

class ExpenseArticleDashboardWarehouseLoading extends ExpenseArticleDashboardWarehouseState {}

class ExpenseArticleDashboardWarehouseLoaded extends ExpenseArticleDashboardWarehouseState {
  final List<ExpenseArticleDashboardWarehouse> expenseArticleDashboardWarehouse;

  ExpenseArticleDashboardWarehouseLoaded(this.expenseArticleDashboardWarehouse);
}

class ExpenseArticleDashboardWarehouseError extends ExpenseArticleDashboardWarehouseState {
  final String message;

  ExpenseArticleDashboardWarehouseError(this.message);
}

class ExpenseArticleDashboardWarehouseSuccess extends ExpenseArticleDashboardWarehouseState {
  final String message;

  ExpenseArticleDashboardWarehouseSuccess(this.message);
}
