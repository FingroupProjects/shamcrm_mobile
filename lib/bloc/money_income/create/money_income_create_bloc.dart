import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../api/service/api_service.dart';
import '../../../models/money/cash_register_model.dart';

part 'money_income_create_event.dart';
part 'money_income_create_state.dart';

class MoneyIncomeCreateBloc extends Bloc<MoneyIncomeCreateEvent, MoneyIncomeCreateState> {

  final apiService = ApiService();

  MoneyIncomeCreateBloc() : super(MoneyIncomeCreateState()) {
    on<FetchCashRegisters>(_onFetchCashRegisters);

    add(FetchCashRegisters());
  }

  // TODO make pagination
  Future<void> _onFetchCashRegisters(FetchCashRegisters event, Emitter<MoneyIncomeCreateState> emit) async {
    emit(state.copyWith(status: MoneyIncomeCreateStatus.loading));
    try {
      final cashRegister = await apiService.getCashRegister();
      emit(state.copyWith(
        status: MoneyIncomeCreateStatus.loaded,
        cashRegisters: cashRegister,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MoneyIncomeCreateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}

enum MoneyIncomeCreateStatus {
  initial,

  loading,
  error,
  loaded,
}
