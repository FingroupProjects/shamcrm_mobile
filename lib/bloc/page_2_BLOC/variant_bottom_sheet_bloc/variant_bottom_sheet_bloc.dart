import 'dart:io';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'variant_bottom_sheet_event.dart';
import 'variant_bottom_sheet_state.dart';

// Cache entry with expiration
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool isExpired(Duration ttl) =>
      DateTime.now().difference(timestamp) > ttl;
}

class VariantBottomSheetBloc extends Bloc<VariantBottomSheetEvent, VariantBottomSheetState> {
  final ApiService apiService;

  // Cache configuration
  static const _cacheDuration = Duration(minutes: 2);
  static const _perPage = 15;

  // Cache storage
  _CacheEntry<List<CategoryWithCount>>? _categoriesCache;
  final Map<String, _CacheEntry<List<Variant>>> _variantsCache = {};
  final Map<int, _CacheEntry<List<Variant>>> _categoryVariantsCache = {};

  // Tracking
  final Map<int, bool> _categoryFullyLoaded = {};

  VariantBottomSheetBloc(this.apiService) : super(VariantBottomSheetState.initial()) {
    on<FetchVariants>(_fetchVariants);
    on<FetchMoreVariants>(_fetchMoreVariants);
    on<FetchCategories>(_fetchCategories);
    on<FetchVariantsByCategory>(_fetchVariantsByCategory);
    on<FetchMoreVariantsByCategory>(_fetchMoreVariantsByCategory);
    on<SearchAll>(_searchAll);
    on<FetchMoreSearchResults>(_fetchMoreSearchResults);
    on<ClearCache>(_clearCache);
  }

  // ================== UNIFIED SEARCH ==================
  Future<void> _searchAll(SearchAll event, Emitter<VariantBottomSheetState> emit) async {
    if (event.query.isEmpty) {
      // Clear search state
      emit(state.copyWith(
        searchQuery: null,
        searchCategories: const [],
        searchVariants: const [],
        isSearching: false,
      ));
      return;
    }

    emit(state.copyWith(
      isSearching: true,
      allVariants: const [],
      categoryVariants: const [],
      selectedCategoryId: null,
    ));

    if (!await _checkInternetConnection()) {
      emit(state.copyWith(
        isSearching: false,
        error: 'Нет подключения к интернету',
      ));
      return;
    }

    try {
      // Search in parallel: categories AND variants
      final results = await Future.wait([
        apiService.getCategory(search: event.query),
        apiService.getVariants(page: 1, search: event.query, perPage: _perPage),
      ]);

      final categories = results[0] as List<CategoryData>;
      final variantsResponse = results[1] as dynamic;
      final variants = variantsResponse.data as List<Variant>;
      final pagination = variantsResponse.pagination as VariantPagination;

      // Flatten categories quickly (no count fetching during search)
      final flatCategories = _flattenCategoriesSimple(categories, 0, null);

      emit(state.copyWith(
        isSearching: false,
        searchQuery: event.query,
        searchCategories: flatCategories,
        searchVariants: variants,
        searchVariantsPagination: pagination,
        currentPage: 1,
        allVariants: const [],
        categoryVariants: const [],
        selectedCategoryId: null,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSearching: false,
        error: 'Ошибка поиска: $e',
      ));
    }
  }

  // ================== SEARCH PAGINATION ==================
  Future<void> _fetchMoreSearchResults(
      FetchMoreSearchResults event,
      Emitter<VariantBottomSheetState> emit,
      ) async {
    if (state.isLoadingMore) return;
    if (state.searchQuery == null || state.searchQuery!.isEmpty) return;

    final nextPage = event.currentPage + 1;

    // Check if already at last page
    if (state.searchVariantsPagination != null &&
        nextPage > state.searchVariantsPagination!.totalPages) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    if (!await _checkInternetConnection()) {
      emit(state.copyWith(
        isLoadingMore: false,
        error: 'Нет подключения к интернету',
      ));
      return;
    }

    try {
      final response = await apiService.getVariants(
        page: nextPage,
        search: state.searchQuery!,
        perPage: _perPage,
      );

      // Merge with existing (remove duplicates)
      final existingIds = state.searchVariants.map((v) => v.id).toSet();
      final newVariants = response.data.where((v) => !existingIds.contains(v.id)).toList();
      final allVariants = [...state.searchVariants, ...newVariants];

      emit(state.copyWith(
        isLoadingMore: false,
        searchVariants: allVariants,
        searchVariantsPagination: response.pagination,
        currentPage: nextPage,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        error: 'Не удалось загрузить дополнительные результаты: $e',
      ));
    }
  }

  // Simple flatten without count fetching (fast)
  List<CategoryWithCount> _flattenCategoriesSimple(
      List<CategoryData> categories,
      int level,
      int? parentId,
      ) {
    final result = <CategoryWithCount>[];

    for (final category in categories) {
      // Add category without count
      result.add(CategoryWithCount(
        category: category,
        goodsCount: 0, // Not used anymore
        level: level,
        parentId: parentId,
      ));

      // Process subcategories
      if (category.subcategories.isNotEmpty) {
        final subCategories = category.subcategories.map((sub) => CategoryData(
          id: sub.id,
          name: sub.name,
          image: sub.image,
          subcategories: sub.subcategories,
        )).toList();

        result.addAll(_flattenCategoriesSimple(subCategories, level + 1, category.id));
      }
    }

    return result;
  }

  // ================== ALL VARIANTS ==================
  Future<void> _fetchVariants(FetchVariants event, Emitter<VariantBottomSheetState> emit) async {
    final cacheKey = 'all_${event.page}';

    // Check cache
    if (!event.forceReload && _variantsCache[cacheKey]?.isExpired(_cacheDuration) == false) {
      final cached = _variantsCache[cacheKey]!.data;
      emit(state.copyWith(
        isLoading: false,
        allVariants: cached,
        allVariantsPagination: state.allVariantsPagination,
        categories: const [], // Clear categories
        categoryVariants: const [], // Clear category variants
        selectedCategoryId: null, // Clear selected category
        searchQuery: null, // Clear search
        searchCategories: const [],
        searchVariants: const [],
        error: null,
      ));
      return;
    }

    emit(state.copyWith(
      isLoading: true,
      categories: const [],
      categoryVariants: const [],
      selectedCategoryId: null,
      searchQuery: null,
      searchCategories: const [],
      searchVariants: const [],
    ));

    if (!await _checkInternetConnection()) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Нет подключения к интернету',
      ));
      return;
    }

    try {
      final response = await apiService.getVariants(
        page: event.page,
        perPage: _perPage,
      );

      // Cache the result
      _variantsCache[cacheKey] = _CacheEntry(response.data);

      emit(state.copyWith(
        isLoading: false,
        allVariants: response.data,
        allVariantsPagination: response.pagination,
        currentPage: event.page,
        categories: const [],
        categoryVariants: const [],
        selectedCategoryId: null,
        searchQuery: null,
        searchCategories: const [],
        searchVariants: const [],
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить варианты: $e',
      ));
    }
  }

  Future<void> _fetchMoreVariants(FetchMoreVariants event, Emitter<VariantBottomSheetState> emit) async {
    if (state.isLoadingMore) return;

    final nextPage = event.currentPage + 1;
    final cacheKey = 'all_$nextPage';

    // Check if already at last page
    if (state.allVariantsPagination != null &&
        nextPage > state.allVariantsPagination!.totalPages) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    if (!await _checkInternetConnection()) {
      emit(state.copyWith(
        isLoadingMore: false,
        error: 'Нет подключения к интернету',
      ));
      return;
    }

    try {
      final response = await apiService.getVariants(
        page: nextPage,
        perPage: _perPage,
      );

      // Cache the page
      _variantsCache[cacheKey] = _CacheEntry(response.data);

      // Merge with existing data (remove duplicates)
      final existingIds = state.allVariants.map((v) => v.id).toSet();
      final newVariants = response.data.where((v) => !existingIds.contains(v.id)).toList();
      final allVariants = [...state.allVariants, ...newVariants];

      emit(state.copyWith(
        isLoadingMore: false,
        allVariants: allVariants,
        allVariantsPagination: response.pagination,
        currentPage: nextPage,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        error: 'Не удалось загрузить дополнительные варианты: $e',
      ));
    }
  }

  // ================== CATEGORIES ==================
  Future<void> _fetchCategories(FetchCategories event, Emitter<VariantBottomSheetState> emit) async {
    // Check cache (skip if force reload or searching)
    if (!event.forceReload &&
        event.search == null &&
        _categoriesCache?.isExpired(_cacheDuration) == false) {
      emit(state.copyWith(
        isLoading: false,
        categories: _categoriesCache!.data,
        allVariants: const [], // Clear all variants
        categoryVariants: const [], // Clear category variants
        selectedCategoryId: null, // Clear selected category
        searchQuery: null, // Clear search
        searchCategories: const [],
        searchVariants: const [],
        error: null,
      ));
      return;
    }

    emit(state.copyWith(
      isLoading: true,
      allVariants: const [],
      categoryVariants: const [],
      selectedCategoryId: null,
      searchQuery: null,
      searchCategories: const [],
      searchVariants: const [],
    ));

    if (!await _checkInternetConnection()) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Нет подключения к интернету',
      ));
      return;
    }

    try {
      // Step 1: Fetch categories structure (FAST - no counts)
      final categories = await apiService.getCategory(search: event.search);

      if (categories.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          categories: [],
          allVariants: const [],
          categoryVariants: const [],
          selectedCategoryId: null,
          searchQuery: null,
          searchCategories: const [],
          searchVariants: const [],
          error: null,
        ));
        return;
      }

      // Step 2: Flatten structure quickly
      final flatCategories = _flattenCategoriesSimple(categories, 0, null);

      // Show categories immediately
      emit(state.copyWith(
        isLoading: false,
        categories: flatCategories,
        allVariants: const [],
        categoryVariants: const [],
        selectedCategoryId: null,
        searchQuery: null,
        searchCategories: const [],
        searchVariants: const [],
        error: null,
      ));

      // Cache the result
      if (event.search == null) {
        _categoriesCache = _CacheEntry(flatCategories);
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить категории: $e',
      ));
    }
  }


  // ================== CATEGORY VARIANTS ==================
  Future<void> _fetchVariantsByCategory(
      FetchVariantsByCategory event,
      Emitter<VariantBottomSheetState> emit,
      ) async {
    // Check cache
    if (!event.forceReload &&
        _categoryVariantsCache[event.categoryId]?.isExpired(_cacheDuration) == false) {
      final cached = _categoryVariantsCache[event.categoryId]!.data;
      emit(state.copyWith(
        isLoading: false,
        selectedCategoryId: event.categoryId,
        categoryVariants: cached,
        allVariants: const [], // Clear all variants
        searchQuery: null, // Clear search
        searchCategories: const [],
        searchVariants: const [],
        error: null,
      ));
      return;
    }

    emit(state.copyWith(
      isLoading: true,
      selectedCategoryId: event.categoryId,
      allVariants: const [],
      searchQuery: null,
      searchCategories: const [],
      searchVariants: const [],
    ));

    if (!await _checkInternetConnection()) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Нет подключения к интернету',
      ));
      return;
    }

    try {
      final response = await apiService.getVariants(
        page: event.page,
        perPage: _perPage,
        filters: {'category_id': event.categoryId},
      );

      // Cache the result
      _categoryVariantsCache[event.categoryId] = _CacheEntry(response.data);
      _categoryFullyLoaded[event.categoryId] = response.data.length < _perPage;

      emit(state.copyWith(
        isLoading: false,
        categoryVariants: response.data,
        categoryVariantsPagination: response.pagination,
        currentPage: event.page,
        allVariants: const [],
        searchQuery: null,
        searchCategories: const [],
        searchVariants: const [],
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить товары категории: $e',
      ));
    }
  }

  Future<void> _fetchMoreVariantsByCategory(
      FetchMoreVariantsByCategory event,
      Emitter<VariantBottomSheetState> emit,
      ) async {
    if (state.isLoadingMore) return;
    if (_categoryFullyLoaded[event.categoryId] == true) return;

    final nextPage = event.currentPage + 1;

    emit(state.copyWith(isLoadingMore: true));

    if (!await _checkInternetConnection()) {
      emit(state.copyWith(
        isLoadingMore: false,
        error: 'Нет подключения к интернету',
      ));
      return;
    }

    try {
      final response = await apiService.getVariants(
        page: nextPage,
        perPage: _perPage,
        filters: {'category_id': event.categoryId},
      );

      // Merge with existing (remove duplicates)
      final existingIds = state.categoryVariants.map((v) => v.id).toSet();
      final newVariants = response.data.where((v) => !existingIds.contains(v.id)).toList();
      final allVariants = [...state.categoryVariants, ...newVariants];

      _categoryFullyLoaded[event.categoryId] = newVariants.length < _perPage;

      emit(state.copyWith(
        isLoadingMore: false,
        categoryVariants: allVariants,
        categoryVariantsPagination: response.pagination,
        currentPage: nextPage,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        error: 'Не удалось загрузить дополнительные товары: $e',
      ));
    }
  }

  // ================== CACHE MANAGEMENT ==================
  Future<void> _clearCache(ClearCache event, Emitter<VariantBottomSheetState> emit) async {
    _categoriesCache = null;
    _variantsCache.clear();
    _categoryVariantsCache.clear();
    _categoryFullyLoaded.clear();
  }

  // ================== UTILITIES ==================
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}