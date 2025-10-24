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
