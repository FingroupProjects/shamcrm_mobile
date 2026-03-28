import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/good_variants_model.dart';
import 'sales_dashboard_goods_movement_event.dart';
import 'sales_dashboard_goods_movement_state.dart';

class SalesDashboardGoodsMovementBloc extends Bloc<SalesDashboardGoodsMovementEvent, SalesDashboardGoodsMovementState> {
  final ApiService _apiService = ApiService();
  
  List<GoodVariantItem>? _cachedVariants;
  int _currentPage = 1;
  int _totalPages = 1;
  DateTime? _lastLoadTime;
  static const Duration _cacheExpiration = Duration(minutes: 1);
  
  // Флаг для отслеживания фоновой загрузки
  bool _isBackgroundLoading = false;
  
  // Текущие параметры запроса
  Map<String, dynamic>? _currentFilter;
  String? _currentSearch;

  SalesDashboardGoodsMovementBloc() : super(SalesDashboardGoodsMovementInitial()) {
    on<LoadGoodsMovementReport>(_onLoadGoodsMovementReport);
    on<RefreshGoodsMovementReport>(_onRefreshGoodsMovementReport);
    on<UpdateGoodsMovementInBackground>(_updateVariantsInBackground);
  }

  bool get _isCacheValid {
    if (_cachedVariants == null || _lastLoadTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastLoadTime!) < _cacheExpiration;
  }

  Future<void> _onLoadGoodsMovementReport(
    LoadGoodsMovementReport event,
    Emitter<SalesDashboardGoodsMovementState> emit,
  ) async {
    try {
      // Сохраняем текущие параметры запроса
      _currentFilter = event.filter;
      _currentSearch = event.search;

      // Initial load (page 1)
      if (event.page == 1) {
        // Если параметры изменились, сбрасываем кэш
        if (!_isCacheValid || 
            _filterChanged(event.filter) || 
            _searchChanged(event.search)) {
          _cachedVariants = null;
          _lastLoadTime = null;
          _currentPage = 1;
          _totalPages = 1;
        }

        // Если у нас есть валидный кэш с теми же параметрами, используем его
        if (_isCacheValid && _cachedVariants != null) {
          if (kDebugMode) {
            debugPrint('SalesDashboardGoodsMovementBloc: Using cached variants data');
          }
          emit(SalesDashboardGoodsMovementLoaded(
            variants: _cachedVariants!,
            currentPage: _currentPage,
            totalPages: _totalPages,
            hasReachedMax: _currentPage >= _totalPages,
          ));
          return;
        }

        if (!await _checkInternetConnection()) {
          emit(SalesDashboardGoodsMovementError(
            message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.',
          ));
          return;
        }

        emit(SalesDashboardGoodsMovementLoading());

        if (kDebugMode) {
          debugPrint('SalesDashboardGoodsMovementBloc: Loading first page of variants...');
        }

        // Загружаем только первую страницу
        var firstPageResponse = await _apiService.getGoodVariantsForDropdown(
          page: event.page,
          perPage: event.perPage,
          search: event.search,
        );
        var firstPageVariants = firstPageResponse.result?.data ?? [];

        if (kDebugMode) {
          debugPrint('SalesDashboardGoodsMovementBloc: First page loaded with ${firstPageVariants.length} variants');
        }

        // Используем данные пагинации из ответа
        _currentPage = firstPageResponse.result?.pagination?.currentPage ?? 1;
        _totalPages = firstPageResponse.result?.pagination?.totalPages ?? 1;

        // Сразу показываем первую страницу пользователю
        _cachedVariants = firstPageVariants;
        _lastLoadTime = DateTime.now();
        
        emit(SalesDashboardGoodsMovementLoaded(
          variants: firstPageVariants,
          currentPage: _currentPage,
          totalPages: _totalPages,
          hasReachedMax: _currentPage >= _totalPages,
        ));

        // Проверяем, есть ли еще страницы из пагинации
        final hasMorePages = _currentPage < _totalPages;

        if (hasMorePages && !_isBackgroundLoading) {
          if (kDebugMode) {
            debugPrint('SalesDashboardGoodsMovementBloc: Starting background loading of remaining pages...');
          }
          // Загружаем остальные страницы в фоне
          _loadRemainingPagesInBackground(event.perPage, event.search);
        }
      } else {
        // Pagination load (page 2+)
        final currentState = state;
        if (currentState is SalesDashboardGoodsMovementLoaded) {
          final response = await _apiService.getGoodVariantsForDropdown(
            page: event.page,
            perPage: event.perPage,
            search: event.search,
          );

          final newVariants = response.result?.data ?? [];
          _currentPage = response.result?.pagination?.currentPage ?? event.page;
          _totalPages = response.result?.pagination?.totalPages ?? 1;

          // Append new data to existing data
          final updatedVariants = List<GoodVariantItem>.from(currentState.variants)
            ..addAll(newVariants);

          _cachedVariants = updatedVariants;

          emit(SalesDashboardGoodsMovementLoaded(
            variants: updatedVariants,
            currentPage: _currentPage,
            totalPages: _totalPages,
            hasReachedMax: _currentPage >= _totalPages,
          ));
        }
      }
    } catch (e) {
      final currentState = state;

      // If it's a pagination error (not initial load), emit pagination error
      if (event.page > 1 && currentState is SalesDashboardGoodsMovementLoaded) {
        emit(SalesDashboardGoodsMovementPaginationError(
          message: e.toString().replaceAll('Exception: ', ''),
          variants: currentState.variants,
          currentPage: currentState.currentPage,
          totalPages: currentState.totalPages,
          hasReachedMax: currentState.hasReachedMax,
        ));
        // Return to previous loaded state
        emit(currentState);
      } else {
        // Initial load error
        if (kDebugMode) {
          debugPrint('SalesDashboardGoodsMovementBloc: Error loading variants: $e');
        }
        emit(SalesDashboardGoodsMovementError(
          message: e.toString().replaceAll('Exception: ', ''),
        ));
      }
    }
  }

  Future<void> _onRefreshGoodsMovementReport(
    RefreshGoodsMovementReport event,
    Emitter<SalesDashboardGoodsMovementState> emit,
  ) async {
    _cachedVariants = null;
    _lastLoadTime = null;
    _currentPage = 1;
    _totalPages = 1;
    
    // Используем сохраненные параметры
    add(LoadGoodsMovementReport(
      page: 1,
      filter: _currentFilter,
      search: _currentSearch,
    ));
  }

  void _loadRemainingPagesInBackground(int perPage, String? search) {
    _isBackgroundLoading = true;

    // Запускаем асинхронную загрузку без await
    _fetchRemainingPages(perPage, search).then((_) {
      if (kDebugMode) {
        debugPrint('SalesDashboardGoodsMovementBloc: Background loading completed. Total variants: ${_cachedVariants?.length ?? 0}');
      }
      _isBackgroundLoading = false;
    }).catchError((error) {
      if (kDebugMode) {
        debugPrint('SalesDashboardGoodsMovementBloc: Error in background loading: $error');
      }
      _isBackgroundLoading = false;
    });
  }

  Future<void> _fetchRemainingPages(int perPage, String? search) async {
    try {
      List<GoodVariantItem> allVariants = List.from(_cachedVariants ?? []);
      int currentPage = 2;
      bool hasMorePages = true;

      while (hasMorePages) {
        try {
          if (kDebugMode) {
            debugPrint('SalesDashboardGoodsMovementBloc: Loading page $currentPage in background...');
          }

          final pageResponse = await _apiService.getGoodVariantsForDropdown(
            page: currentPage,
            perPage: perPage,
            search: search,
          );
          final pageVariants = pageResponse.result?.data ?? [];
          final pagination = pageResponse.result?.pagination;

          if (pageVariants.isNotEmpty) {
            allVariants.addAll(pageVariants);

            // Обновляем кэш
            _cachedVariants = allVariants;
            _currentPage = pagination?.currentPage ?? currentPage;
            _totalPages = pagination?.totalPages ?? currentPage;

            // Проверяем есть ли еще страницы из пагинации
            if (pagination != null && 
                pagination.currentPage != null && 
                pagination.totalPages != null &&
                pagination.currentPage! >= pagination.totalPages!) {
              hasMorePages = false;
            } else {
              currentPage++;
            }

            // Отправляем событие для обновления UI
            add(UpdateGoodsMovementInBackground(allVariants, _totalPages));

            if (kDebugMode) {
              debugPrint('SalesDashboardGoodsMovementBloc: Background loaded page $currentPage, total: ${allVariants.length}');
            }
          } else {
            hasMorePages = false;
          }

          // Небольшая задержка между запросами
          if (hasMorePages) {
            await Future.delayed(const Duration(milliseconds: 100));
          }

        } catch (e) {
          if (kDebugMode) {
            debugPrint('SalesDashboardGoodsMovementBloc: Error loading page $currentPage in background: $e');
          }
          hasMorePages = false;
        }
      }

      _lastLoadTime = DateTime.now();

    } catch (e) {
      if (kDebugMode) {
        debugPrint('SalesDashboardGoodsMovementBloc: Error in _fetchRemainingPages: $e');
      }
    }
  }

  Future<void> _updateVariantsInBackground(
    UpdateGoodsMovementInBackground event,
    Emitter<SalesDashboardGoodsMovementState> emit,
  ) async {
    // Обновляем состояние без показа загрузки
    emit(SalesDashboardGoodsMovementLoaded(
      variants: event.data,
      currentPage: _currentPage,
      totalPages: event.totalPages,
      isLoadingMore: false,
      hasReachedMax: _currentPage >= event.totalPages,
    ));
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  bool _filterChanged(Map<String, dynamic>? newFilter) {
    if (_currentFilter == null && newFilter == null) return false;
    if (_currentFilter == null || newFilter == null) return true;
    return _currentFilter.toString() != newFilter.toString();
  }

  bool _searchChanged(String? newSearch) {
    return _currentSearch != newSearch;
  }

  List<GoodVariantItem>? getCachedVariants() {
    return _isCacheValid ? _cachedVariants : null;
  }
}

