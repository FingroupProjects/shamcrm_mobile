import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import 'goods_openings_event.dart';
import 'goods_openings_state.dart';

class GoodsOpeningsBloc extends Bloc<GoodsOpeningsEvent, GoodsOpeningsState> {
  final ApiService _apiService = ApiService();

  GoodsOpeningsBloc() : super(GoodsOpeningsInitial()) {
    on<LoadGoodsOpenings>(_onLoadGoodsOpenings);
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

      final response = await _apiService.getGoodsOpenings(search: event.search);

      final goods = response.result ?? [];
      
      emit(GoodsOpeningsLoaded(goods: goods, search: event.search));
    } catch (e) {
      emit(GoodsOpeningsError(message: e.toString()));
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
        message: e.toString(),
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
        message: e.toString(),
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
        message: e.toString(),
      ));
    }
  }
}
