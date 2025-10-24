import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/openings/goods_openings_model.dart';
import 'goods_openings_event.dart';
import 'goods_openings_state.dart';

class GoodsOpeningsBloc extends Bloc<GoodsOpeningsEvent, GoodsOpeningsState> {
  final ApiService _apiService = ApiService();

  GoodsOpeningsBloc() : super(GoodsOpeningsInitial()) {
    on<LoadGoodsOpenings>(_onLoadGoodsOpenings);
    on<RefreshGoodsOpenings>(_onRefreshGoodsOpenings);
    on<DeleteGoodsOpening>(_onDeleteGoodsOpening);
  }

  Future<void> _onLoadGoodsOpenings(
    LoadGoodsOpenings event,
    Emitter<GoodsOpeningsState> emit,
  ) async {
    try {
      if (event.page == 1) {
        emit(GoodsOpeningsLoading());
      }

      final response = await _apiService.getGoodsOpenings(
        search: event.search,
        filter: event.filter,
      );

      final goods = response.result ?? [];
      
      if (event.page == 1) {
        emit(GoodsOpeningsLoaded(
          goods: goods,
          hasReachedMax: goods.length < 20,
          pagination: Pagination(
            total: goods.length,
            count: goods.length,
            per_page: 20,
            current_page: 1,
            total_pages: 1,
          ),
        ));
      } else {
        final currentState = state as GoodsOpeningsLoaded;
        final updatedGoods = List<GoodsOpeningDocument>.from(currentState.goods)
          ..addAll(goods);

        emit(currentState.copyWith(
          goods: updatedGoods,
          hasReachedMax: goods.length < 20,
        ));
      }
    } catch (e) {
      if (event.page == 1) {
        emit(GoodsOpeningsError(message: e.toString()));
      } else {
        emit(GoodsOpeningsPaginationError(message: e.toString()));
      }
    }
  }

  Future<void> _onRefreshGoodsOpenings(
    RefreshGoodsOpenings event,
    Emitter<GoodsOpeningsState> emit,
  ) async {
    add(LoadGoodsOpenings(
      page: 1,
      search: event.search,
      filter: event.filter,
    ));
  }

  Future<void> _onDeleteGoodsOpening(
    DeleteGoodsOpening event,
    Emitter<GoodsOpeningsState> emit,
  ) async {
    try {
      await _apiService.deleteGoodsOpening(event.id);
      
      // Reload the list after successful deletion
      add(LoadGoodsOpenings(page: 1));
    } catch (e) {
      emit(GoodsOpeningsError(message: e.toString()));
    }
  }
}
