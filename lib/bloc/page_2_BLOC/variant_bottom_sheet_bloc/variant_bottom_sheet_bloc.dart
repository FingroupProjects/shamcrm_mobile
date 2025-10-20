import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'variant_bottom_sheet_event.dart';
import 'variant_bottom_sheet_state.dart';

class VariantBottomSheetBloc extends Bloc<VariantBottomSheetEvent, VariantBottomSheetState> {
  final ApiService apiService;
  List<Variant> allVariants = [];
  String? _goodsQuery;
  final int _perPage = 15;
  List<CategoryWithCount>? _cachedCategories;

  // Для отслеживания категорий и их товаров
  Map<int, bool> _categoryVariantsFetched = {};
  
  // Кэш загруженных категорий

  VariantBottomSheetBloc(this.apiService) : super(AllVariantLoading()) {
    on<FetchVariants>(_fetchVariants);
    on<FetchMoreVariants>(_fetchMoreVariants);
    on<FetchCategories>(_fetchCategories);
    // on<FetchMoreCategories>(_fetchMoreCategories);
    on<FetchVariantsByCategory>(_fetchVariantsByCategory);
    on<FetchMoreVariantsByCategory>(_fetchMoreVariantsByCategory);
  }

  Future<void> _fetchVariants(FetchVariants event, Emitter<VariantBottomSheetState> emit) async {
    emit(AllVariantLoading());

    if (await _checkInternetConnection()) {
      try {
        allVariants = [];
        final response = await apiService.getVariants(
          page: event.page,
          search: _goodsQuery,
        );

        allVariants = response.data;

        final pagination = Pagination(
          total: response.pagination.total,
          count: response.pagination.count,
          perPage: response.pagination.perPage,
          currentPage: response.pagination.currentPage,
          totalPages: response.pagination.totalPages,
        );

        emit(AllVariantLoaded(response.data, pagination));
      } catch (e) {
        emit(AllVariantError('Не удалось загрузить варианты: $e'));
      }
    } else {
      emit(AllVariantError('Нет подключения к интернету'));
    }
  }

  Future<void> _fetchMoreVariants(FetchMoreVariants event, Emitter<VariantBottomSheetState> emit) async {
    if (await _checkInternetConnection()) {
      try {
        final response = await apiService.getVariants(
          page: event.currentPage + 1,
          search: _goodsQuery,
        );

        final pagination = Pagination(
          total: response.pagination.total,
          count: response.pagination.count,
          perPage: response.pagination.perPage,
          currentPage: response.pagination.currentPage,
          totalPages: response.pagination.totalPages,
        );

        final uniqueNewVariants = response.data
            .where((newItem) => !allVariants.any((existing) => existing.id == newItem.id))
            .toList();

        allVariants.addAll(uniqueNewVariants);

        emit(AllVariantLoaded(allVariants, pagination, currentPage: response.pagination.currentPage));

      } catch (e) {
        emit(AllVariantError('Не удалось загрузить дополнительные варианты: $e'));
      }
    } else {
      emit(AllVariantError('Нет подключения к интернету'));
    }
  }

  Future<List<CategoryWithCount>> _flattenCategoriesWithCount(
    List<CategoryData> categories,
    int level,
    int? parentId,
  ) async {
    final result = <CategoryWithCount>[];
    
    for (final category in categories) {
      try {
        // Получаем количество товаров для категории/подкатегории
        final response = await apiService.getVariants(
          page: 1,
          perPage: 1,
          filters: {'category_id': category.id},
        );

        final goodsCount = response.pagination.total;

        // Проверяем подкатегории
        List<CategoryWithCount> subCategoriesWithCount = [];
        if (category.subcategories.isNotEmpty) {
          // Конвертируем SubCategoryResponse в CategoryData для обработки
          final subCategories = category.subcategories.map((sub) => CategoryData(
            id: sub.id,
            name: sub.name,
            image: sub.image,
            subcategories: sub.subcategories,
          )).toList();
          
          subCategoriesWithCount = await _flattenCategoriesWithCount(
            subCategories,
            level + 1,
            category.id,
          );
        }

        // Пропускаем подкатегории с нулевым количеством товаров
        if (level > 0 && goodsCount == 0) {
          continue;
        }

        // Пропускаем категории без товаров и без подкатегорий с товарами
        if (level == 0 && goodsCount == 0 && subCategoriesWithCount.isEmpty) {
          continue;
        }

        // Добавляем категорию с количеством товаров
        result.add(CategoryWithCount(
          category: category,
          goodsCount: goodsCount,
          level: level,
          parentId: parentId,
        ));
        
        // Добавляем подкатегории
        result.addAll(subCategoriesWithCount);
      } catch (e) {
        if (level == 0) {
          // Для основных категорий всё равно проверяем подкатегории
          List<CategoryWithCount> subCategoriesWithCount = [];
          if (category.subcategories.isNotEmpty) {
            final subCategories = category.subcategories.map((sub) => CategoryData(
              id: sub.id,
              name: sub.name,
              image: sub.image,
              subcategories: sub.subcategories,
            )).toList();
            
            try {
              subCategoriesWithCount = await _flattenCategoriesWithCount(
                subCategories,
                level + 1,
                category.id,
              );
            } catch (_) {}
          }

          // Если нет подкатегорий с товарами, скрываем категорию
          if (subCategoriesWithCount.isEmpty) {
            continue;
          }

          // Добавляем категорию без товаров, но с подкатегориями
          result.add(CategoryWithCount(
            category: category,
            goodsCount: 0,
            level: level,
            parentId: parentId,
          ));
          
          // Добавляем подкатегории
          result.addAll(subCategoriesWithCount);
        }
      }
    }

    return result;
  }

  // Метод для загрузки категорий с количеством товаров
  Future<void> _fetchCategories(FetchCategories event, Emitter<VariantBottomSheetState> emit) async {
    // Проверяем, есть ли кэшированные категории и не нужно ли обновить
    if (_cachedCategories != null && event.search == null && !event.forceReload) {
      emit(CategoriesLoaded(_cachedCategories!));
      return;
    }
    
    emit(CategoriesLoading());

    if (await _checkInternetConnection()) {
      try {
        // Получаем список категорий
        final categories = await apiService.getCategory(search: event.search);

        if (categories.isEmpty) {
          _cachedCategories = [];
          emit(CategoriesLoaded([]));
          return;
        }

        // Разворачиваем категории с подкатегориями и получаем количество товаров
        final categoriesWithCount = await _flattenCategoriesWithCount(categories, 0, null);

        // Сохраняем в кэш только если нет поиска
        if (event.search == null) {
          _cachedCategories = categoriesWithCount;
        }

        emit(CategoriesLoaded(categoriesWithCount));
      } catch (e) {
        if (kDebugMode) {
          print('Error loading categories: $e');
        }
        emit(CategoriesError('Не удалось загрузить категории: $e'));
      }
    } else {
      emit(CategoriesError('Нет подключения к интернету'));
    }
  }

  // Метод для загрузки вариантов по категории
  Future<void> _fetchVariantsByCategory(FetchVariantsByCategory event, Emitter<VariantBottomSheetState> emit) async {
    emit(CategoryVariantsLoading(event.categoryId));

    if (await _checkInternetConnection()) {
      try {
        final response = await apiService.getVariants(
          page: event.page,
          perPage: _perPage,
          filters: {'category_id': event.categoryId},
        );

        _categoryVariantsFetched[event.categoryId] = response.data.length < _perPage;

        emit(CategoryVariantsLoaded(
          categoryId: event.categoryId,
          variants: response.data,
          pagination: response.pagination,
          currentPage: event.page,
        ));
      } catch (e) {
        if (kDebugMode) {
          print('Error loading variants for category ${event.categoryId}: $e');
        }
        emit(CategoryVariantsError('Не удалось загрузить товары категории: $e'));
      }
    } else {
      emit(CategoryVariantsError('Нет подключения к интернету'));
    }
  }

  // Метод для загрузки дополнительных вариантов по категории
  Future<void> _fetchMoreVariantsByCategory(FetchMoreVariantsByCategory event, Emitter<VariantBottomSheetState> emit) async {
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
        emit(CategoryVariantsError('Не удалось загрузить дополнительные товары: $e'));
      }
    } else {
      emit(CategoryVariantsError('Нет подключения к интернету'));
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
