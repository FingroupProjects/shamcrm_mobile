import '../../../../models/page_2/openings/goods_opening_filter.dart';

abstract class GoodsOpeningsEvent {}

class LoadGoodsOpenings extends GoodsOpeningsEvent {
  final String? search;
  final GoodsOpeningFilter? filters;

  /// true — записать [filters], в том числе пустой после «Сбросить».
  final bool updateFilters;

  LoadGoodsOpenings({
    this.search,
    this.filters,
    this.updateFilters = false,
  });
}

class LoadMoreGoodsOpenings extends GoodsOpeningsEvent {
  LoadMoreGoodsOpenings();
}

class RefreshGoodsOpenings extends GoodsOpeningsEvent {
  RefreshGoodsOpenings();
}

class DeleteGoodsOpening extends GoodsOpeningsEvent {
  final int id;

  DeleteGoodsOpening({required this.id});
}

class CreateGoodsOpening extends GoodsOpeningsEvent {
  final int goodVariantId;
  final int supplierId;
  final double price;
  final double quantity;
  final int unitId;
  final int storageId;

  CreateGoodsOpening({
    required this.goodVariantId,
    required this.supplierId,
    required this.price,
    required this.quantity,
    required this.unitId,
    required this.storageId,
  });
}

class UpdateGoodsOpening extends GoodsOpeningsEvent {
  final int id;
  final int goodVariantId;
  final int supplierId;
  final double price;
  final double quantity;
  final int unitId;
  final int storageId;

  UpdateGoodsOpening({
    required this.id,
    required this.goodVariantId,
    required this.supplierId,
    required this.price,
    required this.quantity,
    required this.unitId,
    required this.storageId,
  });
}

// Events for good variants
class LoadGoodsOpeningsGoodVariants extends GoodsOpeningsEvent {
  final int page;
  final int perPage;

  LoadGoodsOpeningsGoodVariants({
    this.page = 1,
    this.perPage = 15,
  });
}

class RefreshGoodsOpeningsGoodVariants extends GoodsOpeningsEvent {}
