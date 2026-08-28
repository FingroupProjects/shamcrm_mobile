import 'dart:async';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/openings/supplier_openings_model.dart';
import 'supplier_openings_event.dart';
import 'supplier_openings_state.dart';

class SupplierOpeningsBloc extends Bloc<SupplierOpeningsEvent, SupplierOpeningsState> {
  final ApiService _apiService = ApiService();
  static const int _perPage = 20;

  int _currentPage = 1;
  int _loadToken = 0;
  List<SupplierOpening> _allItems = [];
  String? _search;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;

  SupplierOpeningsBloc() : super(SupplierOpeningsInitial()) {
    on<LoadSupplierOpenings>(_onLoadSupplierOpenings);
    on<LoadMoreSupplierOpenings>(_onLoadMoreSupplierOpenings);
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

      _currentPage = 1;
      _search = event.search;
      _hasReachedMax = false;
      _isLoadingMore = false;
      final token = ++_loadToken;

      final response = await _apiService.getSupplierOpenings(
        search: event.search,
        page: _currentPage,
        perPage: _perPage,
      );
      if (token != _loadToken) return;

      final suppliers = response.result ?? [];
      _allItems = List.from(suppliers);
      _hasReachedMax = response.pagination?.reachedMax(
            fetchedCount: suppliers.length,
            perPage: _perPage,
          ) ??
          suppliers.length < _perPage;

      emit(SupplierOpeningsLoaded(
        suppliers: List.from(_allItems),
        search: event.search,
        hasReachedMax: _hasReachedMax,
      ));
    } catch (e) {
      emit(SupplierOpeningsError(message: friendlyError(e)));
    }
  }

  Future<void> _onLoadMoreSupplierOpenings(
    LoadMoreSupplierOpenings event,
    Emitter<SupplierOpeningsState> emit,
  ) async {
    if (_isLoadingMore || _hasReachedMax) return;

    _isLoadingMore = true;
    final token = _loadToken;
    try {
      final nextPage = _currentPage + 1;
      final response = await _apiService.getSupplierOpenings(
        search: _search,
        page: nextPage,
        perPage: _perPage,
      );
      if (token != _loadToken) return;

      final suppliers = response.result ?? [];
      final existingIds = _allItems.map((e) => e.id).toSet();
      final uniqueSuppliers =
          suppliers.where((item) => !existingIds.contains(item.id)).toList();
      _currentPage = nextPage;
      _allItems.addAll(uniqueSuppliers);
      _hasReachedMax = uniqueSuppliers.isEmpty ||
          (response.pagination?.reachedMax(
                fetchedCount: suppliers.length,
                perPage: _perPage,
              ) ??
              suppliers.length < _perPage);

      emit(SupplierOpeningsLoaded(
        suppliers: List.from(_allItems),
        search: _search,
        hasReachedMax: _hasReachedMax,
      ));
    } catch (_) {
      // Keep the already loaded list visible.
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _onRefreshSupplierOpenings(
    RefreshSupplierOpenings event,
    Emitter<SupplierOpeningsState> emit,
  ) async {
    // Сохраняем текущий search при обновлении
    final currentState = state;
    String? currentSearch;
    if (currentState is SupplierOpeningsLoaded) {
      currentSearch = currentState.search;
    }
    add(LoadSupplierOpenings(search: currentSearch));
  }

  Future<void> _onDeleteSupplierOpening(
    DeleteSupplierOpening event,
    Emitter<SupplierOpeningsState> emit,
  ) async {
    try {
      await _apiService.deleteSupplierOpening(event.id);

      debugPrint("Supplier opening with ID ${event.id} deleted successfully.");
      
      // Emit success state
      emit(SupplierOpeningDeleteSuccess());
      
      // Reload the list after successful deletion, сохраняем search
      final currentState = state;
      String? currentSearch;
      if (currentState is SupplierOpeningsLoaded) {
        currentSearch = currentState.search;
      }
      add(LoadSupplierOpenings(search: currentSearch));
    } catch (e) {
      // Сохраняем текущее состояние и эмитим операционную ошибку
      emit(SupplierOpeningDeleteError(
        message: friendlyError(e),
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
      
      // Reload the list after successful creation, сохраняем search
      final currentState = state;
      String? currentSearch;
      if (currentState is SupplierOpeningsLoaded) {
        currentSearch = currentState.search;
      }
      add(LoadSupplierOpenings(search: currentSearch));
    } catch (e) {
      // Эмитим ошибку создания
      emit(SupplierOpeningCreateError(
        message: friendlyError(e),
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
      
      // Reload the list after successful edit, сохраняем search
      final currentState = state;
      String? currentSearch;
      if (currentState is SupplierOpeningsLoaded) {
        currentSearch = currentState.search;
      }
      add(LoadSupplierOpenings(search: currentSearch));
    } catch (e) {
      // Эмитим ошибку обновления для показа в snackbar
      emit(SupplierOpeningUpdateError(
        message: friendlyError(e),
      ));
    }
  }
}
