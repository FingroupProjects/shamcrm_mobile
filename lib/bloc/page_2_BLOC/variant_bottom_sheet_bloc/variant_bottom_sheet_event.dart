abstract class VariantBottomSheetEvent {}

class FetchVariants extends VariantBottomSheetEvent {
  final int page;
  final bool forceReload;
  final bool? isService;  // ADD THIS
  FetchVariants({this.page = 1, this.forceReload = false, this.isService});  // ADD isService
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
  final bool? isService;  // ADD THIS
  FetchVariantsByCategory({
    required this.categoryId,
    this.categoryName,
    this.page = 1,
    this.forceReload = false,
    this.isService,  // ADD THIS
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
  final bool? isService;  // ADD THIS
  SearchAll(this.query, {this.isService});  // ADD isService
}

// Подгрузка следующей страницы результатов поиска
class FetchMoreSearchResults extends VariantBottomSheetEvent {
  final int currentPage;
  FetchMoreSearchResults(this.currentPage);
}

// Очистка кеша
class ClearCache extends VariantBottomSheetEvent {}