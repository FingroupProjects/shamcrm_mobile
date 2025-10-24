abstract class GoodsOpeningsEvent {}

class LoadGoodsOpenings extends GoodsOpeningsEvent {
  final int page;
  final String? search;
  final Map<String, dynamic>? filter;

  LoadGoodsOpenings({
    this.page = 1,
    this.search,
    this.filter,
  });
}

class RefreshGoodsOpenings extends GoodsOpeningsEvent {
  final String? search;
  final Map<String, dynamic>? filter;

  RefreshGoodsOpenings({
    this.search,
    this.filter,
  });
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
