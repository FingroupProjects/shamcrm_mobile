/// Фильтр списка первоначальных остатков по товарам.
/// Пустые списки и пустые даты на сервер не уходят.
class GoodsOpeningFilter {
  final List<int> goodIds;
  final List<int> categoryIds;
  final List<int> storageIds;
  final List<int> authorIds;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const GoodsOpeningFilter({
    this.goodIds = const [],
    this.categoryIds = const [],
    this.storageIds = const [],
    this.authorIds = const [],
    this.dateFrom,
    this.dateTo,
  });

  static const empty = GoodsOpeningFilter();

  bool get isActive =>
      goodIds.isNotEmpty ||
      categoryIds.isNotEmpty ||
      storageIds.isNotEmpty ||
      authorIds.isNotEmpty ||
      dateFrom != null ||
      dateTo != null;
}
