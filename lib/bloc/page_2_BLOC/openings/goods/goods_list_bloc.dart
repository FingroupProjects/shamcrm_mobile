import 'dart:io';
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/openings/goods/goods_list_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/openings/goods/goods_list_state.dart';
import 'package:crm_task_manager/models/page_2/good_variants_model.dart';
import 'package:flutter/foundation.dart';

class GetAllGoodsListBloc extends Bloc<GetAllGoodsListEvent, GetAllGoodsListState> {
  List<GoodVariantItem>? _cachedGoods;
  int _currentPage = 1;
  int _totalPages = 1;
  DateTime? _lastLoadTime;
  static const Duration _cacheExpiration = Duration(minutes: 5);
  final apiService = ApiService();

  // Флаг для отслеживания фоновой загрузки
  bool _isBackgroundLoading = false;

  GetAllGoodsListBloc() : super(GetAllGoodsListInitial()) {
    on<GetAllGoodsListEv>(_getGoods);
    on<RefreshAllGoodsListEv>(_refreshGoods);
    on<UpdateGoodsListInBackground>(_updateGoodsInBackground);
  }

  bool get _isCacheValid {
    if (_cachedGoods == null || _lastLoadTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastLoadTime!) < _cacheExpiration;
  }

  Future<void> _getGoods(GetAllGoodsListEv event, Emitter<GetAllGoodsListState> emit) async {
    // Если у нас есть валидный кэш, используем его
    if (_isCacheValid && _cachedGoods != null) {
      if (kDebugMode) {
        print('GetAllGoodsListBloc: Using cached goods data');
      }
      emit(GetAllGoodsListSuccess(
        goodsList: _cachedGoods!,
        currentPage: _currentPage,
        totalPages: _totalPages,
      ));
      return;
    }

    await _loadGoodsProgressive(emit);
  }

  Future<void> _refreshGoods(RefreshAllGoodsListEv event, Emitter<GetAllGoodsListState> emit) async {
    _cachedGoods = null;
    _lastLoadTime = null;
    _currentPage = 1;
    _totalPages = 1;
    await _loadGoodsProgressive(emit);
  }

  Future<void> _loadGoodsProgressive(Emitter<GetAllGoodsListState> emit) async {
    if (!await _checkInternetConnection()) {
      emit(GetAllGoodsListError(
          message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'
      ));
      return;
    }

    try {
      emit(GetAllGoodsListLoading());

      if (kDebugMode) {
        print('GetAllGoodsListBloc: Loading first page of goods...');
      }

      // Загружаем только первую страницу
      var firstPageResponse = await apiService.getGoodVariantsForDropdown(page: 1, perPage: 20);
      var firstPageGoods = firstPageResponse.result?.data ?? [];

      if (kDebugMode) {
        print('GetAllGoodsListBloc: First page loaded with ${firstPageGoods.length} goods');
      }

      // Используем данные пагинации из ответа
      _currentPage = firstPageResponse.result?.pagination?.currentPage ?? 1;
      _totalPages = firstPageResponse.result?.pagination?.totalPages ?? 1;

      // Сразу показываем первую страницу пользователю
      _cachedGoods = firstPageGoods;
      _lastLoadTime = DateTime.now();
      emit(GetAllGoodsListSuccess(
        goodsList: firstPageGoods,
        currentPage: _currentPage,
        totalPages: _totalPages,
      ));

      // Проверяем, есть ли еще страницы из пагинации
      final hasMorePages = _currentPage < _totalPages;

      if (hasMorePages && !_isBackgroundLoading) {
        if (kDebugMode) {
          print('GetAllGoodsListBloc: Starting background loading of remaining pages...');
        }
        // Загружаем остальные страницы в фоне
        _loadRemainingPagesInBackground();
      }

    } catch (e) {
      if (kDebugMode) {
        print('GetAllGoodsListBloc: Error loading goods: $e');
      }
      emit(GetAllGoodsListError(message: e.toString()));
    }
  }

  void _loadRemainingPagesInBackground() {
    _isBackgroundLoading = true;

    // Запускаем асинхронную загрузку без await
    _fetchRemainingPages().then((_) {
      if (kDebugMode) {
        print('GetAllGoodsListBloc: Background loading completed. Total goods: ${_cachedGoods?.length ?? 0}');
      }
      _isBackgroundLoading = false;
    }).catchError((error) {
      if (kDebugMode) {
        print('GetAllGoodsListBloc: Error in background loading: $error');
      }
      _isBackgroundLoading = false;
    });
  }

  Future<void> _fetchRemainingPages() async {
    try {
      List<GoodVariantItem> allGoods = List.from(_cachedGoods ?? []);
      int currentPage = 2;
      bool hasMorePages = true;

      while (hasMorePages) {
        try {
          if (kDebugMode) {
            print('GetAllGoodsListBloc: Loading page $currentPage in background...');
          }

          final pageResponse = await apiService.getGoodVariantsForDropdown(page: currentPage, perPage: 20);
          final pageGoods = pageResponse.result?.data ?? [];
          final pagination = pageResponse.result?.pagination;

          if (pageGoods.isNotEmpty) {
            allGoods.addAll(pageGoods);

            // Обновляем кэш
            _cachedGoods = allGoods;
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
            add(UpdateGoodsListInBackground(allGoods, _totalPages));

            if (kDebugMode) {
              print('GetAllGoodsListBloc: Background loaded page $currentPage, total: ${allGoods.length}');
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
            print('GetAllGoodsListBloc: Error loading page $currentPage in background: $e');
          }
          hasMorePages = false;
        }
      }

      _lastLoadTime = DateTime.now();

    } catch (e) {
      if (kDebugMode) {
        print('GetAllGoodsListBloc: Error in _fetchRemainingPages: $e');
      }
    }
  }

  Future<void> _updateGoodsInBackground(UpdateGoodsListInBackground event, Emitter<GetAllGoodsListState> emit) async {
    // Обновляем состояние без показа загрузки
    emit(GetAllGoodsListSuccess(
      goodsList: event.data,
      currentPage: _currentPage,
      totalPages: event.totalPages,
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

  List<GoodVariantItem>? getCachedGoods() {
    return _isCacheValid ? _cachedGoods : null;
  }
}

