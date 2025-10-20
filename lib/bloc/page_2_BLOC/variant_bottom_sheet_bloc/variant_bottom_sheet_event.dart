abstract class VariantBottomSheetEvent {}

class FetchVariants extends VariantBottomSheetEvent {
  final int page;
  FetchVariants({this.page = 1});
}

class FetchMoreVariants extends VariantBottomSheetEvent {
  final int currentPage;
  FetchMoreVariants(this.currentPage);
}

class SearchVariants extends VariantBottomSheetEvent {
  final String query;
  SearchVariants(this.query);
}

class FilterVariants extends VariantBottomSheetEvent {
  final Map<String, dynamic> filters;
  FilterVariants(this.filters);
}

// Новые события для работы с категориями
class FetchCategories extends VariantBottomSheetEvent {
  final String? search;
  final bool forceReload;
  FetchCategories({this.search, this.forceReload = false});
}

class FetchVariantsByCategory extends VariantBottomSheetEvent {
  final int categoryId;
  final int page;
  FetchVariantsByCategory({
    required this.categoryId,
    this.page = 1,
  });
}

class FetchMoreVariantsByCategory extends VariantBottomSheetEvent {
  final int categoryId;
  final int currentPage;
  FetchMoreVariantsByCategory({
    required this.categoryId,
    required this.currentPage,
  });
}