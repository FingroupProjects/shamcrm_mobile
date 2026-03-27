abstract class GoodsByIdEvent {}

class FetchGoodsById extends GoodsByIdEvent {
  final int goodsId;
  final bool isFromOrder; // Новый параметр

  FetchGoodsById(this.goodsId, {this.isFromOrder = false});
}
class DeleteGoods extends GoodsByIdEvent {
  final int goodId;
  final int? organizationId;

  DeleteGoods(this.goodId, this.organizationId);
}