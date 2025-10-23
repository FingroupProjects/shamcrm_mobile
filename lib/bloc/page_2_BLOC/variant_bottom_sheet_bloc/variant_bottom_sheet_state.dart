import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';

// Unified state - much simpler!
class VariantBottomSheetState {
  // Loading states
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSearching;

  // Error
  final String? error;

  // All Variants Mode
  final List<Variant> allVariants;
  final VariantPagination? allVariantsPagination;

  // Categories
  final List<CategoryWithCount> categories;

  // Selected Category Mode
  final int? selectedCategoryId;
  final String? selectedCategoryName;
  final List<Variant> categoryVariants;
  final VariantPagination? categoryVariantsPagination;

  // Search Results
  final String? searchQuery;
  final List<CategoryWithCount> searchCategories;
  final List<Variant> searchVariants;
  final VariantPagination? searchVariantsPagination;

  // Pagination tracking
  final int currentPage;

  const VariantBottomSheetState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSearching = false,
    this.error,
    this.allVariants = const [],
    this.allVariantsPagination,
    this.categories = const [],
    this.selectedCategoryId,
    this.selectedCategoryName,
    this.categoryVariants = const [],
    this.categoryVariantsPagination,
    this.searchQuery,
    this.searchCategories = const [],
    this.searchVariants = const [],
    this.searchVariantsPagination,
    this.currentPage = 1,
  });

  factory VariantBottomSheetState.initial() {
    return const VariantBottomSheetState();
  }

  // Simple copyWith for immutability with nullable support
  VariantBottomSheetState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSearching,
    Object? error = _undefined,
    List<Variant>? allVariants,
    Object? allVariantsPagination = _undefined,
    List<CategoryWithCount>? categories,
    Object? selectedCategoryId = _undefined,
    Object? selectedCategoryName = _undefined,
    List<Variant>? categoryVariants,
    Object? categoryVariantsPagination = _undefined,
    Object? searchQuery = _undefined,
    List<CategoryWithCount>? searchCategories,
    List<Variant>? searchVariants,
    Object? searchVariantsPagination = _undefined,
    int? currentPage,
  }) {
    return VariantBottomSheetState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSearching: isSearching ?? this.isSearching,
      error: error == _undefined ? this.error : error as String?,
      allVariants: allVariants ?? this.allVariants,
      allVariantsPagination: allVariantsPagination == _undefined
          ? this.allVariantsPagination
          : allVariantsPagination as VariantPagination?,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId == _undefined
          ? this.selectedCategoryId
          : selectedCategoryId as int?,
      selectedCategoryName: selectedCategoryName == _undefined
          ? this.selectedCategoryName
          : selectedCategoryName as String?,
      categoryVariants: categoryVariants ?? this.categoryVariants,
      categoryVariantsPagination: categoryVariantsPagination == _undefined
          ? this.categoryVariantsPagination
          : categoryVariantsPagination as VariantPagination?,
      searchQuery: searchQuery == _undefined
          ? this.searchQuery
          : searchQuery as String?,
      searchCategories: searchCategories ?? this.searchCategories,
      searchVariants: searchVariants ?? this.searchVariants,
      searchVariantsPagination: searchVariantsPagination == _undefined
          ? this.searchVariantsPagination
          : searchVariantsPagination as VariantPagination?,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  // Helper getters for UI
  bool get hasData =>
      allVariants.isNotEmpty ||
          categories.isNotEmpty ||
          categoryVariants.isNotEmpty ||
          searchCategories.isNotEmpty ||
          searchVariants.isNotEmpty;

  bool get isInSearchMode => searchQuery != null && searchQuery!.isNotEmpty;

  bool get isInCategoryMode => selectedCategoryId != null;

  bool get isInAllVariantsMode =>
      !isInSearchMode && !isInCategoryMode && allVariants.isNotEmpty;
}

// Sentinel value for nullable parameters
const Object _undefined = Object();