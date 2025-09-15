import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../models/money/cash_register_model.dart';

part 'money_references_state.dart';
part 'money_references_event.dart';

class MoneyReferencesBloc extends Bloc<MoneyReferencesEvent, MoneyReferencesState> {
  final apiService = ApiService();

  MoneyReferencesBloc() : super(MoneyReferencesState()) {
    on<FetchCashRegisters>(_onFetchCashRegisters);
    on<DeleteMoneyReference>(_onDeleteMoneyReference);
  }

  Future<void> _onDeleteMoneyReference(DeleteMoneyReference event, Emitter<MoneyReferencesState> emit) async {
    try {
      await apiService.deleteCashRegister(event.id);
      final updatedCashRegisters = state.cashRegisters!.where((cr) => cr.id != event.id).toList();
      emit(state.copyWith(cashRegisters: updatedCashRegisters));
    } catch (e) {
      debugPrint('Error deleting cash register: $e');
    }
  }
  Future<void> _onFetchCashRegisters(FetchCashRegisters event, Emitter<MoneyReferencesState> emit) async {
    emit(state.copyWith(status: MoneyReferencesStatus.initialLoading));
    try {
      final cashRegister = await apiService.getCashRegister();
      debugPrint('MoneyReferencesBloc. Cash Registers: $cashRegister');
      emit(state.copyWith(
        status: MoneyReferencesStatus.initialLoaded,
        cashRegisters: cashRegister,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MoneyReferencesStatus.initialError,
        errorMessage: e.toString(),
      ));
    }
  }
}

enum MoneyReferencesStatus {
  initial,

  initialLoading,
  initialError,
  initialLoaded,
}
