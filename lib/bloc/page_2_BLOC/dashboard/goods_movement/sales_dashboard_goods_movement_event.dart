import '../../../../models/page_2/good_variants_model.dart';

abstract class SalesDashboardGoodsMovementEvent {}

class LoadGoodsMovementReport extends SalesDashboardGoodsMovementEvent {
  final int page;
  final int perPage;
  final Map<String, dynamic>? filter;
  final String? search;

  LoadGoodsMovementReport({
    this.page = 1,
    this.perPage = 20,
    this.filter,
    this.search,
  });
}

class RefreshGoodsMovementReport extends SalesDashboardGoodsMovementEvent {}

// Внутреннее событие для обновления данных в фоне
class UpdateGoodsMovementInBackground extends SalesDashboardGoodsMovementEvent {
  final List<GoodVariantItem> data;
  final int totalPages;
  
  UpdateGoodsMovementInBackground(this.data, this.totalPages);
}

