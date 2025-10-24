import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../api/service/api_service.dart';
import 'cash_register_openings_event.dart';
import 'cash_register_openings_state.dart';

class CashRegisterOpeningsBloc extends Bloc<CashRegisterOpeningsEvent, CashRegisterOpeningsState> {
  final ApiService _apiService = ApiService();

  CashRegisterOpeningsBloc() : super(CashRegisterOpeningsInitial()) {
    on<LoadCashRegisterOpenings>(_onLoadCashRegisterOpenings);
    on<RefreshCashRegisterOpenings>(_onRefreshCashRegisterOpenings);
    on<DeleteCashRegisterOpening>(_onDeleteCashRegisterOpening);
    on<CreateCashRegisterOpening>(_onCreateCashRegisterOpening);
    on<UpdateCashRegisterOpening>(_onUpdateCashRegisterOpening);
  }

  Future<void> _onLoadCashRegisterOpenings(
    LoadCashRegisterOpenings event,
    Emitter<CashRegisterOpeningsState> emit,
  ) async {
    try {
        emit(CashRegisterOpeningsLoading());
      final response = await _apiService.getCashRegisterOpenings();

      final cashRegisters = response.result ?? [];
      emit(CashRegisterOpeningsLoaded(cashRegisters: cashRegisters,));
    } catch (e) {
      emit(CashRegisterOpeningsPaginationError(message: e.toString()));
    }
  }

  Future<void> _onRefreshCashRegisterOpenings(
    RefreshCashRegisterOpenings event,
    Emitter<CashRegisterOpeningsState> emit,
  ) async {
    add(LoadCashRegisterOpenings(
    ));
  }

  Future<void> _onDeleteCashRegisterOpening(
    DeleteCashRegisterOpening event,
    Emitter<CashRegisterOpeningsState> emit,
  ) async {
    try {
      await _apiService.deleteCashRegisterOpening(event.id);
      
      add(LoadCashRegisterOpenings());
    } catch (e) {
      // Сохраняем текущее состояние и эмитим операционную ошибку
      emit(CashRegisterOpeningsOperationError(
        message: e.toString(),
        previousState: state,
      ));
    }
  }

  Future<void> _onCreateCashRegisterOpening(
    CreateCashRegisterOpening event,
    Emitter<CashRegisterOpeningsState> emit,
  ) async {
    try {
      await _apiService.createCashRegisterOpening(
        cashRegisterId: event.cashRegisterId,
        sum: event.sum,
      );
      
      // Reload the list after successful creation
      add(LoadCashRegisterOpenings());
    } catch (e) {
      // Сохраняем текущее состояние и эмитим операционную ошибку
      emit(CashRegisterOpeningsOperationError(
        message: e.toString(),
        previousState: state,
      ));
    }
  }

  Future<void> _onUpdateCashRegisterOpening(
    UpdateCashRegisterOpening event,
    Emitter<CashRegisterOpeningsState> emit,
  ) async {
    try {
      await _apiService.updateCashRegisterOpening(
        id: event.id,
        cashRegisterId: event.cashRegisterId,
        sum: event.sum,
      );

      emit(CashRegisterOpeningUpdateSuccess());
      
      // Reload the list after successful update
      add(LoadCashRegisterOpenings());
    } catch (e) {
      // Сохраняем текущее состояние и эмитим операционную ошибку
      emit(CashRegisterOpeningsOperationError(
        message: e.toString(),
        previousState: state,
      ));
    }
  }
}
