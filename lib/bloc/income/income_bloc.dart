// income_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../api/service/api_service.dart';
import '../../models/money/income_model.dart';

part 'income_state.dart';
part 'income_event.dart';

class IncomeBloc extends Bloc<IncomeEvent, IncomeState> {
  final apiService = ApiService();

  IncomeBloc() : super(const IncomeState()) {
    on<FetchIncomes>(_onFetchIncomes);
    on<LoadMoreIncomes>(_onLoadMoreIncomes);
    on<RefreshIncomes>(_onRefreshIncomes);
    on<DeleteIncome>(_onDeleteIncome);
    on<SearchIncomes>(_onSearchIncomes);
  }

  Future<void> _onDeleteIncome(DeleteIncome event, Emitter<IncomeState> emit) async {
    try {
      await apiService.deleteIncome(event.id);
      final updatedIncomes = state.incomes.where((income) => income.id != event.id).toList();
      emit(state.copyWith(incomes: updatedIncomes));
    } catch (e) {
      debugPrint('Error deleting income: $e');
    }
  }

  Future<void> _onFetchIncomes(FetchIncomes event, Emitter<IncomeState> emit) async {
    emit(state.copyWith(status: IncomeStatus.initialLoading));
    try {
      final response = await apiService.getIncomes(
        page: 1,
        perPage: 15,
        query: event.query,
      );

      emit(state.copyWith(
        status: IncomeStatus.initialLoaded,
        incomes: response.data,
        pagination: response.pagination,
        currentPage: 1,
        searchQuery: event.query,
        hasReachedMax: response.pagination.currentPage >= response.pagination.totalPages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IncomeStatus.initialError,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreIncomes(LoadMoreIncomes event, Emitter<IncomeState> emit) async {
    if (state.hasReachedMax) return;

    emit(state.copyWith(status: IncomeStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final response = await apiService.getIncomes(
        page: nextPage,
        perPage: 15,
        query: state.searchQuery,
      );

      final updatedIncomes = List<IncomeModel>.from(state.incomes)..addAll(response.data);

      emit(state.copyWith(
        status: IncomeStatus.initialLoaded,
        incomes: updatedIncomes,
        pagination: response.pagination,
        currentPage: nextPage,
        hasReachedMax: response.pagination.currentPage >= response.pagination.totalPages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IncomeStatus.initialError,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshIncomes(RefreshIncomes event, Emitter<IncomeState> emit) async {
    emit(state.copyWith(status: IncomeStatus.initialLoading));
    add(FetchIncomes(query: state.searchQuery));
  }

  Future<void> _onSearchIncomes(SearchIncomes event, Emitter<IncomeState> emit) async {
    emit(state.copyWith(status: IncomeStatus.initialLoading));
    add(FetchIncomes(query: event.query));
  }
}
