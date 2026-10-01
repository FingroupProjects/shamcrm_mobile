import 'dart:async';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/good_variants_model.dart';
import 'goods_dialog_event.dart';
import 'goods_dialog_state.dart';

class GoodsDialogBloc extends Bloc<GoodsDialogEvent, GoodsDialogState> {
  final ApiService _apiService = ApiService();
  
  List<GoodVariantItem>? _cachedVariants;
  int _currentPage = 1;
  int _totalPages = 1;
  DateTime? _lastLoadTime;
  static const Duration _cacheExpiration = Duration(minutes: 1);

  // Флаг для отслеживания фоновой загрузки
  bool _isBackgroundLoading = false;
  int _loadId = 0;
  String? _activeSearch;
  int? _activeCategoryId;

  // Размер страницы совпадает с запросом к /good/get/variant.
  static const int _perPage = 20;

  GoodsDialogBloc() : super(GoodsDialogInitial()) {
    on<LoadGoodVariantsForDialog>(_onLoadGoodVariantsForDialog);
    on<RefreshGoodVariantsForDialog>(_onRefreshGoodVariants);
    on<UpdateGoodVariantsInBackground>(_updateVariantsInBackground);
    on<SearchGoodVariantsForDialog>(_onSearchGoodVariantsForDialog);
  }

  bool get _isCacheValid {
    if (_cachedVariants == null || _lastLoadTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastLoadTime!) < _cacheExpiration;
  }

  int _beginNewLoad({String? search, int? categoryId}) {
    _loadId++;
    _activeSearch = search?.trim().isNotEmpty == true ? search!.trim() : null;
    _activeCategoryId = categoryId;
    _isBackgroundLoading = false;
    return _loadId;
  }

  bool _isCurrentLoad(int loadId) => loadId == _loadId && !isClosed;

  Future<void> _onLoadGoodVariantsForDialog(
    LoadGoodVariantsForDialog event,
    Emitter<GoodsDialogState> emit,
  ) async {
    final loadId = _beginNewLoad(
      search: event.search,
      categoryId: event.categoryId,
    );

    // Search or category filter: always hit the server.
    if (_activeSearch != null || _activeCategoryId != null) {
      await _loadVariantsProgressive(
        emit,
        search: _activeSearch,
        categoryId: _activeCategoryId,
        loadId: loadId,
      );
      return;
    }

    // Если у нас есть валидный кэш, используем его
    if (_isCacheValid && _cachedVariants != null) {
      if (kDebugMode) {
        //print('GoodsDialogBloc: Using cached variants data');
      }
      emit(GoodsDialogLoaded(
        variants: _cachedVariants!,
        currentPage: _currentPage,
        totalPages: _totalPages,
      ));
      return;
    }

    await _loadVariantsProgressive(emit, loadId: loadId);
  }

  Future<void> _onSearchGoodVariantsForDialog(
    SearchGoodVariantsForDialog event,
    Emitter<GoodsDialogState> emit,
  ) async {
    final loadId = _beginNewLoad(
      search: event.search,
      categoryId: event.categoryId,
    );
    _cachedVariants = null;
    _lastLoadTime = null;
    _currentPage = 1;
    _totalPages = 1;
    await _loadVariantsProgressive(
      emit,
      search: _activeSearch,
      categoryId: _activeCategoryId,
      loadId: loadId,
    );
  }

  Future<void> _onRefreshGoodVariants(
    RefreshGoodVariantsForDialog event,
    Emitter<GoodsDialogState> emit,
  ) async {
    final categoryId = _activeCategoryId;
    final loadId = _beginNewLoad(categoryId: categoryId);
    _cachedVariants = null;
    _lastLoadTime = null;
    _currentPage = 1;
    _totalPages = 1;
    await _loadVariantsProgressive(
      emit,
      categoryId: categoryId,
      loadId: loadId,
    );
  }

  Future<void> _loadVariantsProgressive(
    Emitter<GoodsDialogState> emit, {
    String? search,
    int? categoryId,
    required int loadId,
  }) async {
    if (!await _checkInternetConnection()) {
      if (!_isCurrentLoad(loadId)) return;
      emit(GoodsDialogError(
        message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.',
      ));
      return;
    }

    try {
      if (!_isCurrentLoad(loadId)) return;
      emit(GoodsDialogLoading());

      if (kDebugMode) {
        //print('GoodsDialogBloc: Loading first page of variants...');
      }

      // Загружаем только первую страницу
      var firstPageResponse = await _apiService.getGoodVariantsForDropdown(
        page: 1,
        perPage: _perPage,
        search: search,
        categoryId: categoryId,
      );
      if (!_isCurrentLoad(loadId)) return;
      var firstPageVariants = firstPageResponse.result?.data ?? [];

      if (kDebugMode) {
        //print('GoodsDialogBloc: First page loaded with ${firstPageVariants.length} variants');
      }

      // Используем данные пагинации из ответа. Число товаров на странице
      // не режем: сервер сам говорит, есть ли ещё страницы.
      _currentPage = firstPageResponse.result?.pagination?.currentPage ?? 1;
      _totalPages = firstPageResponse.result?.pagination?.totalPages ?? 1;

      // Keep the unfiltered cache. A category/search result must not replace it.
      if (search == null && categoryId == null) {
        _cachedVariants = firstPageVariants;
        _lastLoadTime = DateTime.now();
      }

      final hasMorePages = _currentPage < _totalPages;
      emit(GoodsDialogLoaded(
        variants: firstPageVariants,
        currentPage: _currentPage,
        totalPages: _totalPages,
        isLoadingMore: hasMorePages,
      ));

      // Полный список, поиск и фильтр категории догружают страницы одинаково.
      if (hasMorePages && !_isBackgroundLoading) {
        if (kDebugMode) {
          //print('GoodsDialogBloc: Starting background loading of remaining pages...');
        }
        _loadRemainingPagesInBackground(
          loadId,
          firstPageVariants,
          search: search,
          categoryId: categoryId,
        );
      }

    } catch (e) {
      if (!_isCurrentLoad(loadId)) return;
      if (kDebugMode) {
        //print('GoodsDialogBloc: Error loading variants: $e');
      }
      emit(GoodsDialogError(message: friendlyError(e)));
    }
  }

  void _loadRemainingPagesInBackground(
    int loadId,
    List<GoodVariantItem> seed, {
    String? search,
    int? categoryId,
  }) {
    _isBackgroundLoading = true;

    // Запускаем асинхронную загрузку без await.
    // search и categoryId зафиксированы на момент старта, чтобы следующая
    // страница не ушла уже с другим запросом.
    _fetchRemainingPages(
      loadId,
      seed,
      search: search,
      categoryId: categoryId,
    ).then((_) {
      if (kDebugMode) {
        //print('GoodsDialogBloc: Background loading completed. Total variants: ${_cachedVariants?.length ?? 0}');
      }
      if (_isCurrentLoad(loadId)) {
        _isBackgroundLoading = false;
      }
    }).catchError((error) {
      if (kDebugMode) {
        //print('GoodsDialogBloc: Error in background loading: $error');
      }
      if (_isCurrentLoad(loadId)) {
        _isBackgroundLoading = false;
      }
    });
  }

  Future<void> _fetchRemainingPages(
    int loadId,
    List<GoodVariantItem> seed, {
    String? search,
    int? categoryId,
  }) async {
    try {
      final allVariants = List<GoodVariantItem>.from(seed);
      var currentPage = 2;
      var hasMorePages = true;

      while (hasMorePages) {
        // Новый поиск или фильтр сменяет loadId — старую догрузку останавливаем.
        if (!_isCurrentLoad(loadId)) {
          return;
        }

        try {
          if (kDebugMode) {
            //print('GoodsDialogBloc: Loading page $currentPage in background...');
          }

          final pageResponse = await _apiService.getGoodVariantsForDropdown(
            page: currentPage,
            perPage: _perPage,
            search: search,
            categoryId: categoryId,
          );
          if (!_isCurrentLoad(loadId)) {
            return;
          }
          final pageVariants = pageResponse.result?.data ?? [];
          final pagination = pageResponse.result?.pagination;

          if (pageVariants.isNotEmpty) {
            allVariants.addAll(pageVariants);

            // В кэш попадает только полный список без поиска и категории.
            if (search == null && categoryId == null) {
              _cachedVariants = List<GoodVariantItem>.from(allVariants);
            }
            _currentPage = pagination?.currentPage ?? currentPage;
            _totalPages = pagination?.totalPages ?? currentPage;

            // Конец только когда сервер сказал, что текущая страница последняя.
            if (pagination != null &&
                pagination.currentPage != null &&
                pagination.totalPages != null &&
                pagination.currentPage! >= pagination.totalPages!) {
              hasMorePages = false;
            } else {
              currentPage++;
            }

            if (_isCurrentLoad(loadId)) {
              add(UpdateGoodVariantsInBackground(
                List<GoodVariantItem>.from(allVariants),
                _totalPages,
                loadId,
                currentPage: _currentPage,
              ));
            }

            if (kDebugMode) {
              //print('GoodsDialogBloc: Background loaded page $currentPage, total: ${allVariants.length}');
            }
          } else {
            hasMorePages = false;
            // Пустая страница: товары уже на экране, спиннер «Загрузка страницы…» выключаем.
            _finishBackgroundLoad(loadId, allVariants);
          }

          if (hasMorePages) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        } catch (e) {
          if (kDebugMode) {
            //print('GoodsDialogBloc: Error loading page $currentPage in background: $e');
          }
          hasMorePages = false;
          _finishBackgroundLoad(loadId, allVariants);
        }
      }

      if (_isCurrentLoad(loadId) && search == null && categoryId == null) {
        _lastLoadTime = DateTime.now();
      }
    } catch (e) {
      if (kDebugMode) {
        //print('GoodsDialogBloc: Error in _fetchRemainingPages: $e');
      }
    }
  }

  // Сообщает списку, что догрузка этой выборки закончилась.
  void _finishBackgroundLoad(int loadId, List<GoodVariantItem> variants) {
    if (!_isCurrentLoad(loadId)) return;
    final lastPage = _totalPages < 1 ? 1 : _totalPages;
    _currentPage = lastPage;
    add(UpdateGoodVariantsInBackground(
      List<GoodVariantItem>.from(variants),
      lastPage,
      loadId,
      currentPage: lastPage,
    ));
  }

  Future<void> _updateVariantsInBackground(
    UpdateGoodVariantsInBackground event,
    Emitter<GoodsDialogState> emit,
  ) async {
    if (!_isCurrentLoad(event.loadId)) {
      return;
    }
    // Обновляем список без полноэкранной загрузки.
    // currentPage берём из события, чтобы поздний обработчик не увидел уже финальную страницу.
    final stillLoading = event.currentPage < event.totalPages;
    emit(GoodsDialogLoaded(
      variants: event.data,
      currentPage: event.currentPage,
      totalPages: event.totalPages,
      isLoadingMore: stillLoading,
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

  List<GoodVariantItem>? getCachedVariants() {
    return _isCacheValid ? _cachedVariants : null;
  }
}
