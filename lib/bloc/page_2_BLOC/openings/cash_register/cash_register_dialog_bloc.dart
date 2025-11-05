import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import 'cash_register_dialog_event.dart';
import 'cash_register_dialog_state.dart';

class CashRegisterDialogBloc extends Bloc<CashRegisterDialogEvent, CashRegisterDialogState> {
  final ApiService _apiService = ApiService();

  CashRegisterDialogBloc() : super(CashRegisterDialogInitial()) {
    on<LoadCashRegistersForDialog>(_onLoadCashRegistersForDialog);
  }

  Future<void> _onLoadCashRegistersForDialog(
    LoadCashRegistersForDialog event,
    Emitter<CashRegisterDialogState> emit,
  ) async {
    try {
      emit(CashRegisterDialogLoading());
      
      final cashRegisters = await _apiService.getCashRegisters();
      
      emit(CashRegisterDialogLoaded(cashRegisters: cashRegisters));
    } catch (e) {
      emit(CashRegisterDialogError(message: e.toString()));
    }
  }
}

