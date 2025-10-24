import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import 'supplier_dialog_event.dart';
import 'supplier_dialog_state.dart';

class SupplierDialogBloc extends Bloc<SupplierDialogEvent, SupplierDialogState> {
  final ApiService _apiService = ApiService();

  SupplierDialogBloc() : super(SupplierDialogInitial()) {
    on<LoadSuppliersForDialog>(_onLoadSuppliersForDialog);
  }

  Future<void> _onLoadSuppliersForDialog(
    LoadSuppliersForDialog event,
    Emitter<SupplierDialogState> emit,
  ) async {
    try {
      emit(SupplierDialogLoading());
      
      final suppliers = await _apiService.getSuppliers();
      
      emit(SupplierDialogLoaded(suppliers: suppliers));
    } catch (e) {
      emit(SupplierDialogError(message: e.toString()));
    }
  }
}

