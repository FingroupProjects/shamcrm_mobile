abstract class VariantEvent {}

class FetchVariants extends VariantEvent {
  final int page;
  FetchVariants({this.page = 1});
}

class FetchMoreVariants extends VariantEvent {
  final int currentPage;
  FetchMoreVariants(this.currentPage);
}

class SearchVariants extends VariantEvent {
  final String query;
  SearchVariants(this.query);
}

class FilterVariants extends VariantEvent {
  final Map<String, dynamic> filters;
  FilterVariants(this.filters);
}

// Новые события для работы с категориями
class FetchCategories extends VariantEvent {
  final String? search;
  final bool forceReload;
  FetchCategories({this.search, this.forceReload = false});
}

class FetchVariantsByCategory extends VariantEvent {
  final int categoryId;
  final int page;
  FetchVariantsByCategory({
    required this.categoryId,
    this.page = 1,
  });
}

class FetchMoreVariantsByCategory extends VariantEvent {
  final int categoryId;
  final int currentPage;
  FetchMoreVariantsByCategory({
    required this.categoryId,
    required this.currentPage,
  });
}