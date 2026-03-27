import 'dart:async';
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

  Future<void> _onLoadGoodVariantsForDialog(
    LoadGoodVariantsForDialog event,
    Emitter<GoodsDialogState> emit,
  ) async {
    // Если есть поиск, не используем кэш
    if (event.search != null && event.search!.isNotEmpty) {
      await _loadVariantsProgressive(emit, search: event.search);
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

    await _loadVariantsProgressive(emit);
  }

  Future<void> _onSearchGoodVariantsForDialog(
    SearchGoodVariantsForDialog event,
    Emitter<GoodsDialogState> emit,
  ) async {
    // При поиске очищаем кэш
    _cachedVariants = null;
    _lastLoadTime = null;
    _currentPage = 1;
    _totalPages = 1;
    await _loadVariantsProgressive(emit, search: event.search);
  }

  Future<void> _onRefreshGoodVariants(
    RefreshGoodVariantsForDialog event,
    Emitter<GoodsDialogState> emit,
  ) async {
    _cachedVariants = null;
    _lastLoadTime = null;
    _currentPage = 1;
    _totalPages = 1;
    await _loadVariantsProgressive(emit);
  }

  Future<void> _loadVariantsProgressive(Emitter<GoodsDialogState> emit, {String? search}) async {
    if (!await _checkInternetConnection()) {
      emit(GoodsDialogError(
        message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.',
      ));
      return;
    }

    try {
      emit(GoodsDialogLoading());

      if (kDebugMode) {
        //print('GoodsDialogBloc: Loading first page of variants...');
      }

      // Загружаем только первую страницу
      var firstPageResponse = await _apiService.getGoodVariantsForDropdown(page: 1, perPage: 20, search: search);
      var firstPageVariants = firstPageResponse.result?.data ?? [];

      if (kDebugMode) {
        //print('GoodsDialogBloc: First page loaded with ${firstPageVariants.length} variants');
      }

      // Используем данные пагинации из ответа
      _currentPage = firstPageResponse.result?.pagination?.currentPage ?? 1;
      _totalPages = firstPageResponse.result?.pagination?.totalPages ?? 1;

      // Сразу показываем первую страницу пользователю
      _cachedVariants = firstPageVariants;
      _lastLoadTime = DateTime.now();
      emit(GoodsDialogLoaded(
        variants: firstPageVariants,
        currentPage: _currentPage,
        totalPages: _totalPages,
      ));

      // Проверяем, есть ли еще страницы из пагинации
      final hasMorePages = _currentPage < _totalPages;

      // Если есть поиск, не загружаем остальные страницы в фоне
      if (hasMorePages && !_isBackgroundLoading && search == null) {
        if (kDebugMode) {
          //print('GoodsDialogBloc: Starting background loading of remaining pages...');
        }
        // Загружаем остальные страницы в фоне
        _loadRemainingPagesInBackground();
      }

    } catch (e) {
      if (kDebugMode) {
        //print('GoodsDialogBloc: Error loading variants: $e');
      }
      emit(GoodsDialogError(message: e.toString()));
    }
  }

  void _loadRemainingPagesInBackground() {
    _isBackgroundLoading = true;

    // Запускаем асинхронную загрузку без await
    _fetchRemainingPages().then((_) {
      if (kDebugMode) {
        //print('GoodsDialogBloc: Background loading completed. Total variants: ${_cachedVariants?.length ?? 0}');
      }
      _isBackgroundLoading = false;
    }).catchError((error) {
      if (kDebugMode) {
        //print('GoodsDialogBloc: Error in background loading: $error');
      }
      _isBackgroundLoading = false;
    });
  }

  Future<void> _fetchRemainingPages() async {
    try {
      List<GoodVariantItem> allVariants = List.from(_cachedVariants ?? []);
      int currentPage = 2;
      bool hasMorePages = true;

      while (hasMorePages) {
        try {
          if (kDebugMode) {
            //print('GoodsDialogBloc: Loading page $currentPage in background...');
          }

          final pageResponse = await _apiService.getGoodVariantsForDropdown(page: currentPage, perPage: 20, search: null);
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
            add(UpdateGoodVariantsInBackground(allVariants, _totalPages));

            if (kDebugMode) {
              //print('GoodsDialogBloc: Background loaded page $currentPage, total: ${allVariants.length}');
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
            //print('GoodsDialogBloc: Error loading page $currentPage in background: $e');
          }
          hasMorePages = false;
        }
      }

      _lastLoadTime = DateTime.now();

    } catch (e) {
      if (kDebugMode) {
        //print('GoodsDialogBloc: Error in _fetchRemainingPages: $e');
      }
    }
  }

  Future<void> _updateVariantsInBackground(
    UpdateGoodVariantsInBackground event,
    Emitter<GoodsDialogState> emit,
  ) async {
    // Обновляем состояние без показа загрузки
    emit(GoodsDialogLoaded(
      variants: event.data,
      currentPage: _currentPage,
      totalPages: event.totalPages,
      isLoadingMore: false,
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
