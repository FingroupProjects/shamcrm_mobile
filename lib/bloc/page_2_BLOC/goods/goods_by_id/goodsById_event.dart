abstract class GoodsByIdEvent {}

class FetchGoodsById extends GoodsByIdEvent {
  final int goodsId;

  FetchGoodsById(this.goodsId);
}