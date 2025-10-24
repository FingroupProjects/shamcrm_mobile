import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/openings/supplier_openings_model.dart';
import 'supplier_openings_event.dart';
import 'supplier_openings_state.dart';

class SupplierOpeningsBloc extends Bloc<SupplierOpeningsEvent, SupplierOpeningsState> {
  final ApiService _apiService = ApiService();

  SupplierOpeningsBloc() : super(SupplierOpeningsInitial()) {
    on<LoadSupplierOpenings>(_onLoadSupplierOpenings);
    on<RefreshSupplierOpenings>(_onRefreshSupplierOpenings);
  }

  Future<void> _onLoadSupplierOpenings(
    LoadSupplierOpenings event,
    Emitter<SupplierOpeningsState> emit,
  ) async {
    try {
      if (event.page == 1) {
        emit(SupplierOpeningsLoading());
      }

      final response = await _apiService.getSupplierOpenings(
        search: event.search,
        filter: event.filter,
      );

      final suppliers = response.result ?? [];
      
      if (event.page == 1) {
        emit(SupplierOpeningsLoaded(
          suppliers: suppliers,
          hasReachedMax: suppliers.length < 20,
          pagination: Pagination(
            total: suppliers.length,
            count: suppliers.length,
            per_page: 20,
            current_page: 1,
            total_pages: 1,
          ),
        ));
      } else {
        final currentState = state as SupplierOpeningsLoaded;
        final updatedSuppliers = List<SupplierOpening>.from(currentState.suppliers)
          ..addAll(suppliers);

        emit(currentState.copyWith(
          suppliers: updatedSuppliers,
          hasReachedMax: suppliers.length < 20,
        ));
      }
    } catch (e) {
      if (event.page == 1) {
        emit(SupplierOpeningsError(message: e.toString()));
      } else {
        emit(SupplierOpeningsPaginationError(message: e.toString()));
      }
    }
  }

  Future<void> _onRefreshSupplierOpenings(
    RefreshSupplierOpenings event,
    Emitter<SupplierOpeningsState> emit,
  ) async {
    add(LoadSupplierOpenings(
      page: 1,
      search: event.search,
      filter: event.filter,
    ));
  }
}
