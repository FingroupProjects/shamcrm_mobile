// expense_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../api/service/api_service.dart';
import '../../models/money/expense_model.dart';

part 'expense_state.dart';
part 'expense_event.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final apiService = ApiService();

  ExpenseBloc() : super(const ExpenseState()) {
    on<FetchExpenses>(_onFetchExpenses);
    on<LoadMoreExpenses>(_onLoadMoreExpenses);
    on<RefreshExpenses>(_onRefreshExpenses);
    on<DeleteExpense>(_onDeleteExpense);
    on<SearchExpenses>(_onSearchExpenses);
  }

  Future<void> _onDeleteExpense(DeleteExpense event, Emitter<ExpenseState> emit) async {
    try {
      await apiService.deleteExpense(event.id);
      final updatedExpenses = state.expenses.where((expense) => expense.id != event.id).toList();
      emit(state.copyWith(expenses: updatedExpenses));
    } catch (e) {
      debugPrint('Error deleting expense: $e');
    }
  }

  Future<void> _onFetchExpenses(FetchExpenses event, Emitter<ExpenseState> emit) async {
    emit(state.copyWith(status: ExpenseStatus.initialLoading));
    try {
      final response = await apiService.getExpenses(
        page: 1,
        perPage: 15,
        query: event.query,
      );

      emit(state.copyWith(
        status: ExpenseStatus.initialLoaded,
        expenses: response.data,
        pagination: response.pagination,
        currentPage: 1,
        searchQuery: event.query,
        hasReachedMax: response.pagination.currentPage >= response.pagination.totalPages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.initialError,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreExpenses(LoadMoreExpenses event, Emitter<ExpenseState> emit) async {
    if (state.hasReachedMax) return;

    emit(state.copyWith(status: ExpenseStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final response = await apiService.getExpenses(
        page: nextPage,
        perPage: 15,
        query: state.searchQuery,
      );

      final updatedExpenses = List<ExpenseModel>.from(state.expenses)..addAll(response.data);

      emit(state.copyWith(
        status: ExpenseStatus.initialLoaded,
        expenses: updatedExpenses,
        pagination: response.pagination,
        currentPage: nextPage,
        hasReachedMax: response.pagination.currentPage >= response.pagination.totalPages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.initialError,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshExpenses(RefreshExpenses event, Emitter<ExpenseState> emit) async {
    emit(state.copyWith(status: ExpenseStatus.initialLoading));
    add(FetchExpenses(query: state.searchQuery));
  }

  Future<void> _onSearchExpenses(SearchExpenses event, Emitter<ExpenseState> emit) async {
    emit(state.copyWith(status: ExpenseStatus.initialLoading));
    add(FetchExpenses(query: event.query));
  }
}
