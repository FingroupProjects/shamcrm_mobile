import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../models/money/cash_register_model.dart';

part 'cash_desk_state.dart';
part 'cash_desk_event.dart';

class CashDeskBloc extends Bloc<CashDeskEvent, CashDeskState> {
  final apiService = ApiService();

  CashDeskBloc() : super(CashDeskState()) {
    on<FetchCashRegisters>(_onFetchCashRegisters);
    on<DeleteCashDesk>(_onDeleteCashDesk);
  }

  Future<void> _onDeleteCashDesk(DeleteCashDesk event, Emitter<CashDeskState> emit) async {
    try {
      await apiService.deleteCashRegister(event.id);
      final updatedCashRegisters = state.cashRegisters!.where((cr) => cr.id != event.id).toList();
      emit(state.copyWith(cashRegisters: updatedCashRegisters));
    } catch (e) {
      debugPrint('Error deleting cash register: $e');
    }
  }
  Future<void> _onFetchCashRegisters(FetchCashRegisters event, Emitter<CashDeskState> emit) async {
    emit(state.copyWith(status: CashDeskStatus.initialLoading));
    try {
      final cashRegister = await apiService.getCashRegister();
      debugPrint('MoneyReferencesBloc. Cash Registers: $cashRegister');
      emit(state.copyWith(
        status: CashDeskStatus.initialLoaded,
        cashRegisters: cashRegister,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CashDeskStatus.initialError,
        errorMessage: e.toString(),
      ));
    }
  }
}

enum CashDeskStatus {
  initial,

  initialLoading,
  initialError,
  initialLoaded,
}
