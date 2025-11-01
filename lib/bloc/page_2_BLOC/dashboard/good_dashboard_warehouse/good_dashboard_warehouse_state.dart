// good_dashboard_warehouse_state.dart
import 'package:crm_task_manager/models/page_2/good_dashboard_warehouse_model.dart';
import 'package:flutter/material.dart';

@immutable
sealed class GoodDashboardWarehouseState {}

final class GoodDashboardWarehouseInitial extends GoodDashboardWarehouseState {}

final class GoodDashboardWarehouseLoading extends GoodDashboardWarehouseState {}

final class GoodDashboardWarehouseLoaded extends GoodDashboardWarehouseState {
  final List<GoodDashboardWarehouse> goodDashboardWarehouse;

  GoodDashboardWarehouseLoaded(this.goodDashboardWarehouse);
}

final class GoodDashboardWarehouseError extends GoodDashboardWarehouseState {
  final String message;

  GoodDashboardWarehouseError(this.message);
}

final class GoodDashboardWarehouseSuccess extends GoodDashboardWarehouseState {
  final String message;

  GoodDashboardWarehouseSuccess(this.message);
}