abstract class VariantBottomSheetEvent {}

class FetchVariants extends VariantBottomSheetEvent {
  final int page;
  final bool forceReload;
  FetchVariants({this.page = 1, this.forceReload = false});
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
  final String? categoryName;
  final int page;
  final bool forceReload;
  FetchVariantsByCategory({
    required this.categoryId,
    this.categoryName,
    this.page = 1,
    this.forceReload = false,
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

// Унифицированный поиск по категориям И товарам
class SearchAll extends VariantBottomSheetEvent {
  final String query;
  SearchAll(this.query);
}

// Подгрузка следующей страницы результатов поиска
class FetchMoreSearchResults extends VariantBottomSheetEvent {
  final int currentPage;
  FetchMoreSearchResults(this.currentPage);
}

// Очистка кеша
class ClearCache extends VariantBottomSheetEvent {}