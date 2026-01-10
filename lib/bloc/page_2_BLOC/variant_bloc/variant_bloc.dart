import 'dart:io';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'variant_event.dart';
import 'variant_state.dart';

class VariantBloc extends Bloc<VariantEvent, VariantState> {
  final ApiService apiService;
  List<Variant> allVariants = [];
  bool allVariantsFetched = false;
  final int _perPage = 15;
  String? _currentQuery;
  Map<String, dynamic>? _currentFilters;

  // Для отслеживания категорий и их товаров
  Map<int, bool> _categoryVariantsFetched = {};
  
  // Кэш загруженных категорий
  List<CategoryWithCount>? _cachedCategories;

  VariantBloc(this.apiService) : super(VariantInitial()) {
    on<FetchVariants>(_fetchVariants);
    on<FetchMoreVariants>(_fetchMoreVariants);
    on<SearchVariants>(_searchVariants);
    on<FilterVariants>(_filterVariants);
    on<FetchCategories>(_fetchCategories);
    on<FetchVariantsByCategory>(_fetchVariantsByCategory);
    on<FetchMoreVariantsByCategory>(_fetchMoreVariantsByCategory);
  }

  Future<void> _fetchVariants(FetchVariants event, Emitter<VariantState> emit) async {
    emit(VariantLoading());

    if (await _checkInternetConnection()) {
      try {
        allVariants = [];
        final response = await apiService.getVariants(
          page: event.page,
          search: _currentQuery,
          filters: _currentFilters, // ← Здесь будут counterparty_id и storage_id
        );

        allVariants = response.data;
        allVariantsFetched = response.data.length < _perPage;

        final pagination = Pagination(
          total: response.pagination.total,
          count: response.pagination.count,
          perPage: response.pagination.perPage,
          currentPage: response.pagination.currentPage,
          totalPages: response.pagination.totalPages,
        );

        if (response.data.isEmpty) {
          emit(VariantEmpty());
        } else {
          emit(VariantDataLoaded(response.data, pagination));
        }
      } catch (e) {
        emit(VariantError('Не удалось загрузить варианты: $e'));
      }
    } else {
      emit(VariantError('Нет подключения к интернету'));
    }
  }

  Future<void> _fetchMoreVariants(FetchMoreVariants event, Emitter<VariantState> emit) async {
    if (allVariantsFetched) return;
    
    // Сохраняем текущее состояние в локальную переменную
    final currentState = state;
    if (currentState is! VariantDataLoaded) return;

    if (await _checkInternetConnection()) {
      try {
        final response = await apiService.getVariants(
          page: event.currentPage + 1,
          search: _currentQuery,
          filters: _currentFilters,
        );

        final uniqueNewVariants =
            response.data.where((newItem) => !allVariants.any((existing) => existing.id == newItem.id)).toList();
        allVariants.addAll(uniqueNewVariants);
        allVariantsFetched = uniqueNewVariants.length < _perPage;

        final newPagination = Pagination(
          total: response.pagination.total,
          count: response.pagination.count,
          perPage: response.pagination.perPage,
          currentPage: response.pagination.currentPage,
          totalPages: response.pagination.totalPages,
        );

        emit(currentState.merge(uniqueNewVariants, newPagination));
      } catch (e) {
        emit(VariantError('Не удалось загрузить дополнительные варианты: $e'));
      }
    } else {
      emit(VariantError('Нет подключения к интернету'));
    }
  }

  Future<void> _searchVariants(SearchVariants event, Emitter<VariantState> emit) async {
    emit(VariantLoading());
    _currentQuery = event.query.isEmpty ? null : event.query;

    if (await _checkInternetConnection()) {
      try {
        final filters = _currentFilters != null ? Map<String, dynamic>.from(_currentFilters!) : {'organization_id': '1'};
        filters['search'] = _currentQuery;

        allVariants = [];
        final response = await apiService.getVariants(page: 1, search: _currentQuery, filters: filters);

        allVariants = response.data;
        allVariantsFetched = response.data.length < _perPage;

        final pagination = Pagination(
          total: response.pagination.total,
          count: response.pagination.count,
          perPage: response.pagination.perPage,
          currentPage: response.pagination.currentPage,
          totalPages: response.pagination.totalPages,
        );

        if (response.data.isEmpty) {
          emit(VariantEmpty());
        } else {
          emit(VariantDataLoaded(response.data, pagination));
        }
      } catch (e) {
        emit(VariantError('Не удалось выполнить поиск вариантов: $e'));
      }
    } else {
      emit(VariantError('Нет подключения к интернету'));
    }
  }

  Future<void> _filterVariants(FilterVariants event, Emitter<VariantState> emit) async {
    emit(VariantLoading());
    _currentFilters = event.filters.isEmpty ? null : Map.from(event.filters);

    if (await _checkInternetConnection()) {
      try {
        final response = await apiService.getVariants(page: 1, search: _currentQuery, filters: _currentFilters);

        allVariants = response.data;
        allVariantsFetched = response.data.length < _perPage;

        final pagination = Pagination(
          total: response.pagination.total,
          count: response.pagination.count,
          perPage: response.pagination.perPage,
          currentPage: response.pagination.currentPage,
          totalPages: response.pagination.totalPages,
        );

        if (response.data.isEmpty) {
          emit(VariantEmpty());
        } else {
          emit(VariantDataLoaded(response.data, pagination));
        }
      } catch (e) {
        emit(VariantError('Не удалось применить фильтры: $e'));
      }
    } else {
      emit(VariantError('Нет подключения к интернету'));
    }
  }

  // Метод для загрузки категорий с количеством товаров
  Future<void> _fetchCategories(FetchCategories event, Emitter<VariantState> emit) async {
    // Проверяем, есть ли кэшированные категории и не нужно ли обновить
    if (_cachedCategories != null && event.search == null && !event.forceReload) {
      if (kDebugMode) {
        print('💾 BLOC: Using cached categories (${_cachedCategories!.length} categories)');
      }
      emit(CategoriesLoaded(_cachedCategories!));
      return;
    }
    
    if (kDebugMode) {
      print('🔄 BLOC: Starting to fetch categories from API');
    }
    emit(CategoriesLoading());

    if (await _checkInternetConnection()) {
      try {
        // Получаем список категорий
        final categories = await apiService.getCategory(search: event.search);
        
        if (kDebugMode) {
          print('📂 BLOC: Loaded ${categories.length} categories from API');
        }

        if (categories.isEmpty) {
          _cachedCategories = [];
          emit(CategoriesLoaded([]));
          return;
        }

        // Для каждой категории получаем количество товаров
        final categoriesWithCount = <CategoryWithCount>[];

        for (final category in categories) {
          try {
            if (kDebugMode) {
              print('  📊 BLOC: Fetching goods count for category: ${category.name}');
            }
            // Получаем первую страницу вариантов для категории с минимальным per_page
            final response = await apiService.getVariants(
              page: 1,
              perPage: 1,
              filters: {'category_id': category.id},
            );

            // Используем total из пагинации как количество товаров
            categoriesWithCount.add(CategoryWithCount(
              category: category,
              goodsCount: response.pagination.total,
            ));
            
            if (kDebugMode) {
              print('  ✅ BLOC: Category ${category.name} has ${response.pagination.total} goods');
            }
          } catch (e) {
            if (kDebugMode) {
              print('  ❌ BLOC: Error getting goods count for category ${category.id}: $e');
            }
            // Если произошла ошибка, добавляем категорию с нулевым количеством товаров
            categoriesWithCount.add(CategoryWithCount(
              category: category,
              goodsCount: 0,
            ));
          }
        }

        // Сохраняем в кэш только если нет поиска
        if (event.search == null) {
          _cachedCategories = categoriesWithCount;
          if (kDebugMode) {
            print('💾 BLOC: Categories cached');
          }
        }

        if (kDebugMode) {
          print('✅ BLOC: All categories loaded with counts');
        }
        emit(CategoriesLoaded(categoriesWithCount));
      } catch (e) {
        if (kDebugMode) {
          print('❌ BLOC: Error loading categories: $e');
        }
        emit(CategoriesError('Не удалось загрузить категории: $e'));
      }
    } else {
      emit(CategoriesError('Нет подключения к интернету'));
    }
  }

  // Метод для загрузки вариантов по категории
  Future<void> _fetchVariantsByCategory(FetchVariantsByCategory event, Emitter<VariantState> emit) async {
    if (kDebugMode) {
      print('🔄 BLOC: Loading variants for category ${event.categoryId}, page ${event.page}');
    }
    emit(CategoryVariantsLoading(event.categoryId));

    if (await _checkInternetConnection()) {
      try {
        final response = await apiService.getVariants(
          page: event.page,
          perPage: _perPage,
          filters: {'category_id': event.categoryId},
        );

        _categoryVariantsFetched[event.categoryId] = response.data.length < _perPage;

        if (kDebugMode) {
          print('✅ BLOC: Loaded ${response.data.length} variants for category ${event.categoryId}');
        }

        if (response.data.isEmpty) {
          emit(VariantEmpty());
        } else {
          emit(CategoryVariantsLoaded(
            categoryId: event.categoryId,
            variants: response.data,
            pagination: response.pagination,
            currentPage: event.page,
          ));
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ BLOC: Error loading variants for category ${event.categoryId}: $e');
        }
        emit(VariantError('Не удалось загрузить товары категории: $e'));
      }
    } else {
      emit(VariantError('Нет подключения к интернету'));
    }
  }

  // Метод для загрузки дополнительных вариантов по категории
  Future<void> _fetchMoreVariantsByCategory(FetchMoreVariantsByCategory event, Emitter<VariantState> emit) async {
    final isFetched = _categoryVariantsFetched[event.categoryId] ?? false;
    if (isFetched) return;
    
    // Сохраняем текущее состояние в локальную переменную
    final currentState = state;
    if (currentState is! CategoryVariantsLoaded) return;
    if (currentState.categoryId != event.categoryId) return;

    if (await _checkInternetConnection()) {
      try {
        final response = await apiService.getVariants(
          page: event.currentPage + 1,
          perPage: _perPage,
          filters: {'category_id': event.categoryId},
        );

        final uniqueNewVariants =
            response.data.where((newItem) => !currentState.variants.any((existing) => existing.id == newItem.id)).toList();

        _categoryVariantsFetched[event.categoryId] = uniqueNewVariants.length < _perPage;

        emit(currentState.merge(uniqueNewVariants, response.pagination));
      } catch (e) {
        emit(VariantError('Не удалось загрузить дополнительные товары: $e'));
      }
    } else {
      emit(VariantError('Нет подключения к интернету'));
    }
  }

  Future<bool> _checkInternetConnection() async {
    // Реализация проверки соединения (аналогична GoodsBloc)
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
