import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/openings/cash_register_openings_model.dart';
import 'cash_register_openings_event.dart';
import 'cash_register_openings_state.dart';

class CashRegisterOpeningsBloc extends Bloc<CashRegisterOpeningsEvent, CashRegisterOpeningsState> {
  final ApiService _apiService = ApiService();

  CashRegisterOpeningsBloc() : super(CashRegisterOpeningsInitial()) {
    on<LoadCashRegisterOpenings>(_onLoadCashRegisterOpenings);
    on<RefreshCashRegisterOpenings>(_onRefreshCashRegisterOpenings);
  }

  Future<void> _onLoadCashRegisterOpenings(
    LoadCashRegisterOpenings event,
    Emitter<CashRegisterOpeningsState> emit,
  ) async {
    try {
      if (event.page == 1) {
        emit(CashRegisterOpeningsLoading());
      }

      final response = await _apiService.getCashRegisterOpenings(
        search: event.search,
        filter: event.filter,
      );

      final cashRegisters = response.result ?? [];
      
      if (event.page == 1) {
        emit(CashRegisterOpeningsLoaded(
          cashRegisters: cashRegisters,
          hasReachedMax: cashRegisters.length < 20,
          pagination: Pagination(
            total: cashRegisters.length,
            count: cashRegisters.length,
            per_page: 20,
            current_page: 1,
            total_pages: 1,
          ),
        ));
      } else {
        final currentState = state as CashRegisterOpeningsLoaded;
        final updatedCashRegisters = List<CashRegisterOpening>.from(currentState.cashRegisters)
          ..addAll(cashRegisters);

        emit(currentState.copyWith(
          cashRegisters: updatedCashRegisters,
          hasReachedMax: cashRegisters.length < 20,
        ));
      }
    } catch (e) {
      if (event.page == 1) {
        emit(CashRegisterOpeningsError(message: e.toString()));
      } else {
        emit(CashRegisterOpeningsPaginationError(message: e.toString()));
      }
    }
  }

  Future<void> _onRefreshCashRegisterOpenings(
    RefreshCashRegisterOpenings event,
    Emitter<CashRegisterOpeningsState> emit,
  ) async {
    add(LoadCashRegisterOpenings(
      page: 1,
      search: event.search,
      filter: event.filter,
    ));
  }
}
