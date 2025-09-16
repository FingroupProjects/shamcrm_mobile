import 'dart:io';
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/cash_register_list/cash_register_list_event.dart';
import 'package:crm_task_manager/bloc/cash_register_list/cash_register_list_state.dart';

class GetAllCashRegisterBloc extends Bloc<GetAllCashRegisterEvent, GetAllCashRegisterState> {
  GetAllCashRegisterBloc() : super(GetAllCashRegisterInitial()) {
    on<GetAllCashRegisterEv>(_getCashRegisters);
  }

  Future<void> _getCashRegisters(GetAllCashRegisterEv event, Emitter<GetAllCashRegisterState> emit) async {
    if (await _checkInternetConnection()) {
      try {
        emit(GetAllCashRegisterLoading());

        var res = await ApiService().getAllCashRegisters();

        emit(GetAllCashRegisterSuccess(dataCashRegisters: res));
      } catch (e) {
        emit(GetAllCashRegisterError(message: e.toString()));
      }
    } else {
      emit(GetAllCashRegisterError(message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}