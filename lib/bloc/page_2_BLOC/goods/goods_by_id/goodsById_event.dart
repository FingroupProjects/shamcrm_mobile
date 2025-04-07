abstract class GoodsByIdEvent {}

class FetchGoodsById extends GoodsByIdEvent {
  final int goodsId;

  FetchGoodsById(this.goodsId);
}

class DeleteGoods extends GoodsByIdEvent {
  final int goodId;
  final int? organizationId;

  DeleteGoods(this.goodId, this.organizationId);
}