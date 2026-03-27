import 'package:crm_task_manager/models/page_2/good_dashboard_warehouse_model.dart';

abstract class GoodDashboardWarehouseEvent {}

class FetchGoodDashboardWarehouse extends GoodDashboardWarehouseEvent {}

class RefreshGoodDashboardWarehouse extends GoodDashboardWarehouseEvent {}

class UpdateGoodsInBackground extends GoodDashboardWarehouseEvent {
  final List<GoodDashboardWarehouse> goods;

  UpdateGoodsInBackground(this.goods);
}