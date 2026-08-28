import 'dart:async';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/openings/cash_register_openings_model.dart';
import 'cash_register_openings_event.dart';
import 'cash_register_openings_state.dart';

class CashRegisterOpeningsBloc extends Bloc<CashRegisterOpeningsEvent, CashRegisterOpeningsState> {
  final ApiService _apiService = ApiService();
  static const int _perPage = 20;

  int _currentPage = 1;
  int _loadToken = 0;
  List<CashRegisterOpening> _allItems = [];
  String? _search;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;

  CashRegisterOpeningsBloc() : super(CashRegisterOpeningsInitial()) {
    on<LoadCashRegisterOpenings>(_onLoadCashRegisterOpenings);
    on<LoadMoreCashRegisterOpenings>(_onLoadMoreCashRegisterOpenings);
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

      _currentPage = 1;
      _search = event.search;
      _hasReachedMax = false;
      _isLoadingMore = false;
      final token = ++_loadToken;
      
      if (kDebugMode) {
        debugPrint('🟡 CashRegisterOpeningsBloc: вызван getCashRegisterOpenings');
      }
      
      final response = await _apiService.getCashRegisterOpenings(
        search: event.search,
        page: _currentPage,
        perPage: _perPage,
      );
      if (token != _loadToken) return;

      if (kDebugMode) {
        debugPrint('🟡 CashRegisterOpeningsBloc: получен response, result: ${response.result?.length ?? 0} элементов');
      }

      final cashRegisters = response.result ?? [];
      _allItems = List.from(cashRegisters);
      _hasReachedMax = response.pagination?.reachedMax(
            fetchedCount: cashRegisters.length,
            perPage: _perPage,
          ) ??
          cashRegisters.length < _perPage;
      
      if (kDebugMode) {
        debugPrint('🟡 CashRegisterOpeningsBloc: cashRegisters count: ${cashRegisters.length}');
        if (cashRegisters.isNotEmpty) {
          debugPrint('🟡 CashRegisterOpeningsBloc: первый элемент id: ${cashRegisters[0].id}, name: ${cashRegisters[0].cashRegister?.name}');
        }
      }
      
      emit(CashRegisterOpeningsLoaded(
        cashRegisters: List.from(_allItems),
        search: event.search,
        hasReachedMax: _hasReachedMax,
      ));
      
      if (kDebugMode) {
        debugPrint('🟢 CashRegisterOpeningsBloc: успешно загружено ${cashRegisters.length} касс');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('🔴 CashRegisterOpeningsBloc: ОШИБКА при загрузке: $e');
        debugPrint('🔴 CashRegisterOpeningsBloc: STACK TRACE: $stackTrace');
      }
      emit(CashRegisterOpeningsError(message: friendlyError(e)));
    }
  }

  Future<void> _onLoadMoreCashRegisterOpenings(
    LoadMoreCashRegisterOpenings event,
    Emitter<CashRegisterOpeningsState> emit,
  ) async {
    if (_isLoadingMore || _hasReachedMax) return;

    _isLoadingMore = true;
    final token = _loadToken;
    try {
      final nextPage = _currentPage + 1;
      final response = await _apiService.getCashRegisterOpenings(
        search: _search,
        page: nextPage,
        perPage: _perPage,
      );
      if (token != _loadToken) return;

      final cashRegisters = response.result ?? [];
      final existingIds = _allItems.map((e) => e.id).toSet();
      final uniqueCashRegisters = cashRegisters
          .where((item) => !existingIds.contains(item.id))
          .toList();
      _currentPage = nextPage;
      _allItems.addAll(uniqueCashRegisters);
      _hasReachedMax = uniqueCashRegisters.isEmpty ||
          (response.pagination?.reachedMax(
                fetchedCount: cashRegisters.length,
                perPage: _perPage,
              ) ??
              cashRegisters.length < _perPage);

      emit(CashRegisterOpeningsLoaded(
        cashRegisters: List.from(_allItems),
        search: _search,
        hasReachedMax: _hasReachedMax,
      ));
    } catch (_) {
      // Keep the already loaded list visible.
    } finally {
      _isLoadingMore = false;
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
