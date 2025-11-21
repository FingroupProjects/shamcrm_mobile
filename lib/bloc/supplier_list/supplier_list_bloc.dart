import 'dart:io';
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/supplier_list/supplier_list_event.dart';
import 'package:crm_task_manager/bloc/supplier_list/supplier_list_state.dart';

class GetAllSupplierBloc extends Bloc<GetAllSupplierEvent, GetAllSupplierState> {
  GetAllSupplierBloc() : super(GetAllSupplierInitial()) {
    on<GetAllSupplierEv>(_getSuppliers);
  }

  Future<void> _getSuppliers(GetAllSupplierEv event, Emitter<GetAllSupplierState> emit) async {
    if (await _checkInternetConnection()) {
      try {
        emit(GetAllSupplierLoading());

        var res = await ApiService().getAllSuppliers();

        emit(GetAllSupplierSuccess(dataSuppliers: res));
      } catch (e) {
        emit(GetAllSupplierError(message: e.toString()));
      }
    } else {
      emit(GetAllSupplierError(message: 'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
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