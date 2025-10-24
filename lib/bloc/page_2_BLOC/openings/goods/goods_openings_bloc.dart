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

      final response = await _apiService.getGoodsOpenings();

      final goods = response.result ?? [];
      
      emit(GoodsOpeningsLoaded(goods: goods));
    } catch (e) {
      emit(GoodsOpeningsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshGoodsOpenings(
    RefreshGoodsOpenings event,
    Emitter<GoodsOpeningsState> emit,
  ) async {
    add(LoadGoodsOpenings());
  }

  Future<void> _onDeleteGoodsOpening(
    DeleteGoodsOpening event,
    Emitter<GoodsOpeningsState> emit,
  ) async {
    try {
      await _apiService.deleteGoodsOpening(event.id);
      
      // Reload the list after successful deletion
      add(LoadGoodsOpenings());
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
      await _apiService.createGoodsOpening(
        goodVariantId: event.goodVariantId,
        supplierId: event.supplierId,
        price: event.price,
        quantity: event.quantity,
        unitId: event.unitId,
        storageId: event.storageId,
      );
      
      // Reload the list after successful creation
      add(LoadGoodsOpenings());
    } catch (e) {
      // Сохраняем текущее состояние и эмитим операционную ошибку
      emit(GoodsOpeningsOperationError(
        message: e.toString(),
        previousState: state,
      ));
    }
  }

  Future<void> _onUpdateGoodsOpening(
    UpdateGoodsOpening event,
    Emitter<GoodsOpeningsState> emit,
  ) async {
    try {
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
      
      // Reload the list after successful update
      add(LoadGoodsOpenings());
    } catch (e) {
      // Сохраняем текущее состояние и эмитим операционную ошибку
      emit(GoodsOpeningsOperationError(
        message: e.toString(),
        previousState: state,
      ));
    }
  }
}
