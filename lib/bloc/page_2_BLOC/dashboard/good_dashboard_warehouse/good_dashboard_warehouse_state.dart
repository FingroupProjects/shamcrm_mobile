import 'package:crm_task_manager/models/page_2/good_dashboard_warehouse_model.dart';

abstract class GoodDashboardWarehouseState {}

class GoodDashboardWarehouseInitial extends GoodDashboardWarehouseState {}

class GoodDashboardWarehouseLoading extends GoodDashboardWarehouseState {}

class GoodDashboardWarehouseLoaded extends GoodDashboardWarehouseState {
  final List<GoodDashboardWarehouse> goodDashboardWarehouse;

  GoodDashboardWarehouseLoaded(this.goodDashboardWarehouse);
}

class GoodDashboardWarehouseError extends GoodDashboardWarehouseState {
  final String message;

  GoodDashboardWarehouseError(this.message);
}

class GoodDashboardWarehouseSuccess extends GoodDashboardWarehouseState {
  final String message;

  GoodDashboardWarehouseSuccess(this.message);
}