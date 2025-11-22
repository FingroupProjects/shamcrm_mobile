// ============================================
// expense_article_dashboard_warehouse_bloc.dart
// ============================================
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/expense_article_dashboard_warehouse/expense_article_dashboard_warehouse_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/expense_article_dashboard_warehouse/expense_article_dashboard_warehouse_state.dart';
import 'package:flutter/material.dart';

class ExpenseArticleDashboardWarehouseBloc extends Bloc<ExpenseArticleDashboardWarehouseEvent, ExpenseArticleDashboardWarehouseState> {
  final ApiService apiService;
  bool allExpenseArticleDashboardWarehouseFetched = false;

  ExpenseArticleDashboardWarehouseBloc(this.apiService) : super(ExpenseArticleDashboardWarehouseInitial()) {
    on<FetchExpenseArticleDashboardWarehouse>(_fetchExpenseArticleDashboardWarehouse);
  }

  Future<void> _fetchExpenseArticleDashboardWarehouse(
    FetchExpenseArticleDashboardWarehouse event,
    Emitter<ExpenseArticleDashboardWarehouseState> emit,
  ) async {
    emit(ExpenseArticleDashboardWarehouseLoading());

    if (await _checkInternetConnection()) {
      try {
        final expenseArticleDashboardWarehouse = await apiService.getExpenseArticleDashboardWarehouse();
        allExpenseArticleDashboardWarehouseFetched = expenseArticleDashboardWarehouse.isEmpty;
        emit(ExpenseArticleDashboardWarehouseLoaded(expenseArticleDashboardWarehouse));
      } catch (e) {
        debugPrint('Ошибка при загрузке статей расхода!');
        emit(ExpenseArticleDashboardWarehouseError('Не удалось загрузить список Статей расхода!'));
      }
    } else {
      emit(ExpenseArticleDashboardWarehouseError('Нет подключения к интернету'));
    }
  }

  // Method to check internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}
