import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/supplier_bloc/supplier_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/supplier_bloc/supplier_state.dart';

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final ApiService apiService;
  bool allSupplierFetched = false;

  SupplierBloc(this.apiService) : super(SupplierInitial()) {
    on<FetchSupplier>(_fetchSupplier);
  }

  Future<void> _fetchSupplier(FetchSupplier event, Emitter<SupplierState> emit) async {
    emit(SupplierLoading());

    if (await _checkInternetConnection()) {
      try {
        final supplierList = await apiService.getSupplier(); 
        allSupplierFetched = supplierList.isEmpty;
        emit(SupplierLoaded(supplierList)); 
      } catch (e) {
        //print('Ошибка при загрузке поставщиков!'); // For debugging
        emit(SupplierError('Не удалось загрузить список поставщиков!'));
      }
    } else {
      emit(SupplierError('Нет подключения к интернету'));
    }
  }

  // Method to check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      return false;
    }
  }
}