import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_state.dart';
import 'package:flutter/foundation.dart';

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final ApiService apiService;
  bool allSupplierFetched = false;

  SupplierBloc(this.apiService) : super(SupplierInitial()) {
    on<FetchSupplier>(_fetchSupplier);
    on<AddSupplier>(_createSupplier);
    on<DeleteSupplier>(_deleteSupplier);
    on<UpdateSupplier>(_updateSupplier);
  }

  Future<void> _fetchSupplier(
      FetchSupplier event, Emitter<SupplierState> emit) async {
    emit(SupplierLoading());

    if (await _checkInternetConnection()) {
      try {
        final supplierList = await apiService.getSupplier();
        allSupplierFetched = supplierList.isEmpty;
        emit(SupplierLoaded(supplierList));
      } catch (e) {
        //print('Ошибка при загрузке поставщиков!'); // For debugging
        if (kDebugMode) {
          print(e);
        }
        emit(SupplierError('Не удалось загрузить список поставщиков!'));
      }
    } else {
      emit(SupplierError('Нет подключения к интернету'));
    }
  }

  Future<void> _createSupplier(
      AddSupplier event, Emitter<SupplierState> emit) async {
    emit(SupplierLoading());
    if (await _checkInternetConnection()) {
      try {
        final organizationId = await apiService.getSelectedOrganization() ?? '';
        final salesFunnelId = await apiService.getSelectedSalesFunnel() ?? '';

        final result = await apiService.createSupplier(
            event.supplier, organizationId, salesFunnelId);
        emit(SupplierSuccess("screated"));
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        emit(SupplierError('Не удалось создать поля поставщика!'));
      }
    } else {
      emit(SupplierError('Нет подключения к интернету'));
    }
  }

  Future<void> _deleteSupplier(
      DeleteSupplier event, Emitter<SupplierState> emit) async {
    emit(SupplierLoading());
    if (await _checkInternetConnection()) {
      try {
        await apiService.deleteSupplier(event.supplierId);
        final supplierList = await apiService.getSupplier();
        emit(SupplierLoaded(supplierList));
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        emit(SupplierError('Не удалось удалить поставщика!'));
      }
    } else {
      emit(SupplierError('Нет подключения к интернету'));
    }
  }

  Future<void> _updateSupplier(
      UpdateSupplier event, Emitter<SupplierState> emit) async {
    emit(SupplierLoading());
    if (await _checkInternetConnection()) {
      try {
        await apiService.updateSupplier(id: event.id, supplier: event.supplier);
        final supplierList = await apiService.getSupplier();
        emit(SupplierLoaded(supplierList));
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        emit(SupplierError('Не удалось обновить поставщика!'));
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
