
import 'package:crm_task_manager/models/page_2/category_dashboard_warehouse_model.dart';

abstract class CategoryDashboardWarehouseState {}

class CategoryDashboardWarehouseInitial extends CategoryDashboardWarehouseState {}

class CategoryDashboardWarehouseLoading extends CategoryDashboardWarehouseState {}

class CategoryDashboardWarehouseLoaded extends CategoryDashboardWarehouseState {
  final List<CategoryDashboardWarehouse> categoryDashboardWarehouse;

  CategoryDashboardWarehouseLoaded(this.categoryDashboardWarehouse);
}

class CategoryDashboardWarehouseError extends CategoryDashboardWarehouseState {
  final String message;

  CategoryDashboardWarehouseError(this.message);
}

class CategoryDashboardWarehouseSuccess extends CategoryDashboardWarehouseState {
  final String message;

  CategoryDashboardWarehouseSuccess(this.message);
}