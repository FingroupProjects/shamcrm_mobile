import 'dart:io';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/openings/goods/goods_list_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/openings/goods/goods_list_state.dart';
import 'package:crm_task_manager/models/page_2/good_variants_model.dart';
import 'package:flutter/foundation.dart';

class GetAllGoodsListBloc
    extends Bloc<GetAllGoodsListEvent, GetAllGoodsListState> {
  List<GoodVariantItem>? _cachedGoods;
  int _currentPage = 1;
  int _totalPages = 1;
  DateTime? _lastLoadTime;
  static const Duration _cacheExpiration = Duration(minutes: 1);
  final apiService = ApiService();

  GetAllGoodsListBloc() : super(GetAllGoodsListInitial()) {
    on<GetAllGoodsListEv>(_getGoods);
    on<RefreshAllGoodsListEv>(_refreshGoods);
  }

  bool get _isCacheValid {
    if (_cachedGoods == null || _lastLoadTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastLoadTime!) < _cacheExpiration;
  }

  Future<void> _getGoods(
      GetAllGoodsListEv event, Emitter<GetAllGoodsListState> emit) async {
    // Если у нас есть валидный кэш, используем его
    if (_isCacheValid && _cachedGoods != null) {
      if (kDebugMode) {
        //print('GetAllGoodsListBloc: Using cached goods data');
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

  Future<void> _refreshGoods(
      RefreshAllGoodsListEv event, Emitter<GetAllGoodsListState> emit) async {
    _cachedGoods = null;
    _lastLoadTime = null;
    _currentPage = 1;
    _totalPages = 1;
    await _loadGoodsProgressive(emit);
  }

  Future<void> _loadGoodsProgressive(Emitter<GetAllGoodsListState> emit) async {
    if (!await _checkInternetConnection()) {
      emit(GetAllGoodsListError(
          message:
              'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
      return;
    }

    try {
      emit(GetAllGoodsListLoading());

      if (kDebugMode) {
        //print('GetAllGoodsListBloc: Loading first page of goods...');
      }

      // Загружаем только первую страницу
      var firstPageResponse =
          await apiService.getGoodVariantsForDropdown(page: 1, perPage: 20);
      var firstPageGoods = firstPageResponse.result?.data ?? [];

      if (kDebugMode) {
        //print('GetAllGoodsListBloc: First page loaded with ${firstPageGoods.length} goods');
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
    } catch (e) {
      if (kDebugMode) {
        //print('GetAllGoodsListBloc: Error loading goods: $e');
      }
      emit(GetAllGoodsListError(message: friendlyError(e)));
    }
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
