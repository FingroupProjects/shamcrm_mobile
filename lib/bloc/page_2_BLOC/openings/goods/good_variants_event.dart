abstract class GoodVariantsEvent {}

class LoadGoodVariants extends GoodVariantsEvent {
  final int page;
  final int perPage;

  LoadGoodVariants({
    this.page = 1,
    this.perPage = 15,
  });
}

class RefreshGoodVariants extends GoodVariantsEvent {}

