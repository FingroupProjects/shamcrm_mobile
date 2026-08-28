import 'dart:async';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/openings/goods_openings_model.dart';
import 'goods_openings_event.dart';
import 'goods_openings_state.dart';

class GoodsOpeningsBloc extends Bloc<GoodsOpeningsEvent, GoodsOpeningsState> {
  final ApiService _apiService = ApiService();
  static const int _perPage = 20;

  int _currentPage = 1;
  int _loadToken = 0;
  List<GoodsOpeningDocument> _allItems = [];
  String? _search;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;

  GoodsOpeningsBloc() : super(GoodsOpeningsInitial()) {
    on<LoadGoodsOpenings>(_onLoadGoodsOpenings);
    on<LoadMoreGoodsOpenings>(_onLoadMoreGoodsOpenings);
    on<RefreshGoodsOpenings>(_onRefreshGoodsOpenings);
    on<DeleteGoodsOpening>(_onDeleteGoodsOpening);
    on<CreateGoodsOpening>(_onCreateGoodsOpening);
    on<UpdateGoodsOpening>(_onUpdateGoodsOpening);
  }

  Future<void> _onLoadGoodsOpenings(
    LoadGoodsOpenings event,
    Emitter<GoodsOpeningsState> emit,
  ) async {
    try {
      emit(GoodsOpeningsLoading());

      _currentPage = 1;
      _search = event.search;
      _hasReachedMax = false;
      _isLoadingMore = false;
      final token = ++_loadToken;

      final response = await _apiService.getGoodsOpenings(
        search: event.search,
        page: _currentPage,
        perPage: _perPage,
      );
      if (token != _loadToken) return;

      final goods = response.result ?? [];
      _allItems = List.from(goods);
      _hasReachedMax = response.pagination?.reachedMax(
            fetchedCount: goods.length,
            perPage: _perPage,
          ) ??
          goods.length < _perPage;

      emit(GoodsOpeningsLoaded(
        goods: List.from(_allItems),
        search: event.search,
        hasReachedMax: _hasReachedMax,
      ));
    } catch (e) {
      emit(GoodsOpeningsError(message: friendlyError(e)));
    }
  }

  Future<void> _onLoadMoreGoodsOpenings(
    LoadMoreGoodsOpenings event,
    Emitter<GoodsOpeningsState> emit,
  ) async {
    if (_isLoadingMore || _hasReachedMax) return;

    _isLoadingMore = true;
    final token = _loadToken;
    try {
      final nextPage = _currentPage + 1;
      final response = await _apiService.getGoodsOpenings(
        search: _search,
        page: nextPage,
        perPage: _perPage,
      );
      if (token != _loadToken) return;

      final goods = response.result ?? [];
      final existingIds = _allItems.map((e) => e.id).toSet();
      final uniqueGoods =
          goods.where((item) => !existingIds.contains(item.id)).toList();
      _currentPage = nextPage;
      _allItems.addAll(uniqueGoods);
      _hasReachedMax = uniqueGoods.isEmpty ||
          (response.pagination?.reachedMax(
                fetchedCount: goods.length,
                perPage: _perPage,
              ) ??
              goods.length < _perPage);

      emit(GoodsOpeningsLoaded(
        goods: List.from(_allItems),
        search: _search,
        hasReachedMax: _hasReachedMax,
      ));
    } catch (_) {
      // Keep the already loaded list visible.
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _onRefreshGoodsOpenings(
    RefreshGoodsOpenings event,
    Emitter<GoodsOpeningsState> emit,
  ) async {
    // Сохраняем текущий search при обновлении
    final currentState = state;
    String? currentSearch;
    if (currentState is GoodsOpeningsLoaded) {
      currentSearch = currentState.search;
    }
    add(LoadGoodsOpenings(search: currentSearch));
  }

  Future<void> _onDeleteGoodsOpening(
    DeleteGoodsOpening event,
    Emitter<GoodsOpeningsState> emit,
  ) async {
    try {
      await _apiService.deleteGoodsOpening(event.id);
      
      // Emit success state
      emit(GoodsOpeningDeleteSuccess());
      
      // Reload the list after successful deletion, сохраняем search
      final currentState = state;
      String? currentSearch;
      if (currentState is GoodsOpeningsLoaded) {
        currentSearch = currentState.search;
      }
      add(LoadGoodsOpenings(search: currentSearch));
    } catch (e) {
      // Сохраняем текущее состояние и эмитим операционную ошибку
      emit(GoodsOpeningsOperationError(
        message: friendlyError(e),
        previousState: state,
      ));
    }
  }

  Future<void> _onCreateGoodsOpening(
    CreateGoodsOpening event,
    Emitter<GoodsOpeningsState> emit,
  ) async {
    try {
      // Эмитим состояние загрузки
      emit(GoodsOpeningCreating());
      
      await _apiService.createGoodsOpening(
        goodVariantId: event.goodVariantId,
        supplierId: event.supplierId,
        price: event.price,
        quantity: event.quantity,
        unitId: event.unitId,
        storageId: event.storageId,
      );
      
      // Эмитим состояние успешного создания
      emit(GoodsOpeningCreateSuccess());
      
      // Reload the list after successful creation, сохраняем search
      final currentState = state;
      String? currentSearch;
      if (currentState is GoodsOpeningsLoaded) {
        currentSearch = currentState.search;
      }
      add(LoadGoodsOpenings(search: currentSearch));
    } catch (e) {
      // Эмитим ошибку создания
      emit(GoodsOpeningCreateError(
        message: friendlyError(e),
      ));
    }
  }

  Future<void> _onUpdateGoodsOpening(
    UpdateGoodsOpening event,
    Emitter<GoodsOpeningsState> emit,
  ) async {
    try {
      // Эмитим состояние загрузки
      emit(GoodsOpeningUpdating());
      
      await _apiService.updateGoodsOpening(
        id: event.id,
        goodVariantId: event.goodVariantId,
        supplierId: event.supplierId,
        price: event.price,
        quantity: event.quantity,
        unitId: event.unitId,
        storageId: event.storageId,
      );
      
      emit(GoodsOpeningUpdateSuccess());
      
      // Reload the list after successful update, сохраняем search
      final currentState = state;
      String? currentSearch;
      if (currentState is GoodsOpeningsLoaded) {
        currentSearch = currentState.search;
      }
      add(LoadGoodsOpenings(search: currentSearch));
    } catch (e) {
      // Эмитим ошибку обновления для показа в snackbar
      emit(GoodsOpeningUpdateError(
        message: friendlyError(e),
      ));
    }
  }
}
