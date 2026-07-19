import 'dart:async';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../api/service/api_service.dart';
import 'cash_register_openings_event.dart';
import 'cash_register_openings_state.dart';

class CashRegisterOpeningsBloc extends Bloc<CashRegisterOpeningsEvent, CashRegisterOpeningsState> {
  final ApiService _apiService = ApiService();

  CashRegisterOpeningsBloc() : super(CashRegisterOpeningsInitial()) {
    on<LoadCashRegisterOpenings>(_onLoadCashRegisterOpenings);
    on<RefreshCashRegisterOpenings>(_onRefreshCashRegisterOpenings);
    on<DeleteCashRegisterOpening>(_onDeleteCashRegisterOpening);
    on<CreateCashRegisterOpening>(_onCreateCashRegisterOpening);
    on<UpdateCashRegisterOpening>(_onUpdateCashRegisterOpening);
  }

  Future<void> _onLoadCashRegisterOpenings(
    LoadCashRegisterOpenings event,
    Emitter<CashRegisterOpeningsState> emit,
  ) async {
    if (kDebugMode) {
      debugPrint('🟡 CashRegisterOpeningsBloc: _onLoadCashRegisterOpenings - начало, search: ${event.search}');
    }
    try {
      emit(CashRegisterOpeningsLoading());
      
      if (kDebugMode) {
        debugPrint('🟡 CashRegisterOpeningsBloc: вызван getCashRegisterOpenings');
      }
      
      final response = await _apiService.getCashRegisterOpenings(search: event.search);

      if (kDebugMode) {
        debugPrint('🟡 CashRegisterOpeningsBloc: получен response, result: ${response.result?.length ?? 0} элементов');
      }

      final cashRegisters = response.result ?? [];
      
      if (kDebugMode) {
        debugPrint('🟡 CashRegisterOpeningsBloc: cashRegisters count: ${cashRegisters.length}');
        if (cashRegisters.isNotEmpty) {
          debugPrint('🟡 CashRegisterOpeningsBloc: первый элемент id: ${cashRegisters[0].id}, name: ${cashRegisters[0].cashRegister?.name}');
        }
      }
      
      emit(CashRegisterOpeningsLoaded(cashRegisters: cashRegisters, search: event.search));
      
      if (kDebugMode) {
        debugPrint('🟢 CashRegisterOpeningsBloc: успешно загружено ${cashRegisters.length} касс');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('🔴 CashRegisterOpeningsBloc: ОШИБКА при загрузке: $e');
        debugPrint('🔴 CashRegisterOpeningsBloc: STACK TRACE: $stackTrace');
      }
      emit(CashRegisterOpeningsPaginationError(message: friendlyError(e)));
    }
  }

  Future<void> _onRefreshCashRegisterOpenings(
    RefreshCashRegisterOpenings event,
    Emitter<CashRegisterOpeningsState> emit,
  ) async {
    // Сохраняем текущий search при обновлении
    final currentState = state;
    String? currentSearch;
    if (currentState is CashRegisterOpeningsLoaded) {
      currentSearch = currentState.search;
    } else if (event.search != null) {
      currentSearch = event.search;
    }
    add(LoadCashRegisterOpenings(search: currentSearch));
  }

  Future<void> _onDeleteCashRegisterOpening(
    DeleteCashRegisterOpening event,
    Emitter<CashRegisterOpeningsState> emit,
  ) async {
    try {
      await _apiService.deleteCashRegisterOpening(event.id);
      
      // Emit success state
      emit(CashRegisterOpeningDeleteSuccess());
      
      // Сохраняем search при перезагрузке
      final currentState = state;
      String? currentSearch;
      if (currentState is CashRegisterOpeningsLoaded) {
        currentSearch = currentState.search;
      }
      add(LoadCashRegisterOpenings(search: currentSearch));
    } catch (e) {
      // Сохраняем текущее состояние и эмитим операционную ошибку
      emit(CashRegisterOpeningsOperationError(
        message: friendlyError(e),
        previousState: state,
      ));
    }
  }

  Future<void> _onCreateCashRegisterOpening(
    CreateCashRegisterOpening event,
    Emitter<CashRegisterOpeningsState> emit,
  ) async {
    try {
      // Эмитим состояние загрузки
      emit(CashRegisterOpeningCreating());
      
      await _apiService.createCashRegisterOpening(
        cashRegisterId: event.cashRegisterId,
        sum: event.sum,
      );
      
      // Эмитим состояние успешного создания
      emit(CashRegisterOpeningCreateSuccess());
      
      // Reload the list after successful creation
      // Сохраняем search при перезагрузке
      final currentState = state;
      String? currentSearch;
      if (currentState is CashRegisterOpeningsLoaded) {
        currentSearch = currentState.search;
      }
      add(LoadCashRegisterOpenings(search: currentSearch));
    } catch (e) {
      // Эмитим ошибку создания
      emit(CashRegisterOpeningCreateError(
        message: friendlyError(e),
      ));
    }
  }

  Future<void> _onUpdateCashRegisterOpening(
    UpdateCashRegisterOpening event,
    Emitter<CashRegisterOpeningsState> emit,
  ) async {
    try {
      // Эмитим состояние загрузки
      emit(CashRegisterOpeningUpdating());
      
      await _apiService.updateCashRegisterOpening(
        id: event.id,
        cashRegisterId: event.cashRegisterId,
        sum: event.sum,
      );

      emit(CashRegisterOpeningUpdateSuccess());
      
      // Reload the list after successful update
      // Сохраняем search при перезагрузке
      final currentState = state;
      String? currentSearch;
      if (currentState is CashRegisterOpeningsLoaded) {
        currentSearch = currentState.search;
      }
      add(LoadCashRegisterOpenings(search: currentSearch));
    } catch (e) {
      // Эмитим ошибку обновления для показа в snackbar
      emit(CashRegisterOpeningUpdateError(
        message: friendlyError(e),
      ));
    }
  }
}
