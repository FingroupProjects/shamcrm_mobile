import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import '../../models/cash_register_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

part 'money_references_event.dart';

part 'money_references_state.dart';

class MoneyReferencesBloc
    extends Bloc<MoneyReferencesEvent, MoneyReferencesState> {
  final apiService = ApiService();

  MoneyReferencesBloc() : super(MoneyReferencesState()) {
    on<FetchCashRegisters>(_onFetchCashRegisters);
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
