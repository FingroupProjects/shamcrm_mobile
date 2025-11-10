// cash_desk_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../api/service/api_service.dart';
import '../../models/money/cash_register_model.dart';

part 'cash_desk_state.dart';
part 'cash_desk_event.dart';

class CashDeskBloc extends Bloc<CashDeskEvent, CashDeskState> {
  final apiService = ApiService();

  CashDeskBloc() : super(const CashDeskState()) {
    on<FetchCashRegisters>(_onFetchCashRegisters);
    on<LoadMoreCashRegisters>(_onLoadMoreCashRegisters);
    on<RefreshCashRegisters>(_onRefreshCashRegisters);
    on<DeleteCashDesk>(_onDeleteCashDesk);
    on<SearchCashRegisters>(_onSearchCashRegisters);
  }

  Future<void> _onDeleteCashDesk(DeleteCashDesk event, Emitter<CashDeskState> emit) async {
    try {
      await apiService.deleteCashRegister(event.id);
      final updatedCashRegisters = state.cashRegisters.where((cr) => cr.id != event.id).toList();
      emit(state.copyWith(cashRegisters: updatedCashRegisters));
    } catch (e) {
      debugPrint('Error deleting cash register: $e');
    }
  }

  Future<void> _onFetchCashRegisters(FetchCashRegisters event, Emitter<CashDeskState> emit) async {
    emit(state.copyWith(status: CashDeskStatus.initialLoading));
    try {
      final response = await apiService.getCashRegister(
        page: 1,
        perPage: 15,
        query: event.query,
      );

      emit(state.copyWith(
        status: CashDeskStatus.initialLoaded,
        cashRegisters: response.data,
        pagination: response.pagination,
        currentPage: 1,
        searchQuery: event.query,
        hasReachedMax: response.pagination.currentPage >= response.pagination.totalPages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CashDeskStatus.initialError,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreCashRegisters(LoadMoreCashRegisters event, Emitter<CashDeskState> emit) async {
    if (state.hasReachedMax || state.status == CashDeskStatus.loadingMore) return;

    emit(state.copyWith(status: CashDeskStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final response = await apiService.getCashRegister(
        page: nextPage,
        perPage: 15,
        query: state.searchQuery,
      );

      final updatedCashRegisters = List<CashRegisterModel>.from(state.cashRegisters)
        ..addAll(response.data);

      emit(state.copyWith(
        status: CashDeskStatus.initialLoaded,
        cashRegisters: updatedCashRegisters,
        pagination: response.pagination,
        currentPage: nextPage,
        hasReachedMax: response.pagination.currentPage >= response.pagination.totalPages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CashDeskStatus.loadMoreError,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshCashRegisters(RefreshCashRegisters event, Emitter<CashDeskState> emit) async {
    emit(state.copyWith(status: CashDeskStatus.refreshing));
    try {
      final response = await apiService.getCashRegister(
        page: 1,
        perPage: 15,
        query: state.searchQuery,
      );

      emit(state.copyWith(
        status: CashDeskStatus.initialLoaded,
        cashRegisters: response.data,
        pagination: response.pagination,
        currentPage: 1,
        hasReachedMax: response.pagination.currentPage >= response.pagination.totalPages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CashDeskStatus.refreshError,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSearchCashRegisters(SearchCashRegisters event, Emitter<CashDeskState> emit) async {
    emit(state.copyWith(status: CashDeskStatus.initialLoading));
    try {
      final response = await apiService.getCashRegister(
        page: 1,
        perPage: 15,
        query: event.query,
      );

      emit(state.copyWith(
        status: CashDeskStatus.initialLoaded,
        cashRegisters: response.data,
        pagination: response.pagination,
        currentPage: 1,
        searchQuery: event.query,
        hasReachedMax: response.pagination.currentPage >= response.pagination.totalPages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CashDeskStatus.searchError,
        errorMessage: e.toString(),
      ));
    }
  }
}
