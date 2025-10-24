import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import 'supplier_openings_event.dart';
import 'supplier_openings_state.dart';

class SupplierOpeningsBloc extends Bloc<SupplierOpeningsEvent, SupplierOpeningsState> {
  final ApiService _apiService = ApiService();

  SupplierOpeningsBloc() : super(SupplierOpeningsInitial()) {
    on<LoadSupplierOpenings>(_onLoadSupplierOpenings);
    on<RefreshSupplierOpenings>(_onRefreshSupplierOpenings);
    on<DeleteSupplierOpening>(_onDeleteSupplierOpening);
    on<CreateSupplierOpening>(_onCreateSupplierOpening);
    on<EditSupplierOpening>(_onEditSupplierOpening);
  }

  Future<void> _onLoadSupplierOpenings(
    LoadSupplierOpenings event,
    Emitter<SupplierOpeningsState> emit,
  ) async {
    try {
      emit(SupplierOpeningsLoading());

      final response = await _apiService.getSupplierOpenings();

      final suppliers = response.result ?? [];
      
      emit(SupplierOpeningsLoaded(suppliers: suppliers));
    } catch (e) {
      emit(SupplierOpeningsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshSupplierOpenings(
    RefreshSupplierOpenings event,
    Emitter<SupplierOpeningsState> emit,
  ) async {
    add(LoadSupplierOpenings());
  }

  Future<void> _onDeleteSupplierOpening(
    DeleteSupplierOpening event,
    Emitter<SupplierOpeningsState> emit,
  ) async {
    try {
      await _apiService.deleteSupplierOpening(event.id);
      
      // Reload the list after successful deletion
      add(LoadSupplierOpenings());
    } catch (e) {
      // Сохраняем текущее состояние и эмитим операционную ошибку
      emit(SupplierOpeningsOperationError(
        message: e.toString(),
        previousState: state,
      ));
    }
  }

  Future<void> _onCreateSupplierOpening(
    CreateSupplierOpening event,
    Emitter<SupplierOpeningsState> emit,
  ) async {
    try {
      // Эмитим состояние загрузки
      emit(SupplierOpeningCreating());
      
      await _apiService.createSupplierOpening(
        supplierId: event.supplierId,
        ourDuty: event.ourDuty,
        debtToUs: event.debtToUs,
      );
      
      // Эмитим состояние успешного создания
      emit(SupplierOpeningCreateSuccess());
      
      // Reload the list after successful creation
      add(LoadSupplierOpenings());
    } catch (e) {
      // Эмитим ошибку создания
      emit(SupplierOpeningCreateError(
        message: e.toString(),
      ));
    }
  }

  Future<void> _onEditSupplierOpening(
    EditSupplierOpening event,
    Emitter<SupplierOpeningsState> emit,
  ) async {
    try {
      // Эмитим состояние загрузки
      emit(SupplierOpeningUpdating());
      
      await _apiService.editSupplierOpening(
        id: event.id,
        supplierId: event.supplierId,
        ourDuty: event.ourDuty,
        debtToUs: event.debtToUs,
      );
      
      emit(SupplierOpeningUpdateSuccess());
      
      // Reload the list after successful edit
      add(LoadSupplierOpenings());
    } catch (e) {
      // Эмитим ошибку обновления для показа в snackbar
      emit(SupplierOpeningUpdateError(
        message: e.toString(),
      ));
    }
  }
}
