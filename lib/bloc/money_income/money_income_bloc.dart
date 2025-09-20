import 'dart:async';

import 'package:crm_task_manager/models/money/money_income_document_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter/foundation.dart';

part 'money_income_event.dart';
part 'money_income_state.dart';

class MoneyIncomeBloc extends Bloc<MoneyIncomeEvent, MoneyIncomeState> {
  final ApiService apiService = ApiService();
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic>? _filters;
  String? _search = '';
  List<Document> _allData = [];


  MoneyIncomeBloc() : super(MoneyIncomeInitial()) {
    on<FetchMoneyIncome>(_onFetchMoneyIncome);
    on<CreateMoneyIncome>(_onCreateMoneyIncome);
    on<UpdateMoneyIncome>(_onUpdateMoneyIncome);
    on<DeleteMoneyIncome>(_onDeleteMoneyIncome);
    on<RestoreMoneyIncome>(_onRestoreMoneyIncome);
    on<AddMoneyIncome>(_onAddMoneyIncome);
  }

  Future<void> _onAddMoneyIncome(AddMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeNavigateToAdd());
  }

  Future<void> _onFetchMoneyIncome(FetchMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    // Always emit loading for force refresh or initial load
    if (event.forceRefresh || _allData.isEmpty) {
      emit(MoneyIncomeLoading());
    }

    if (event.forceRefresh) {
      _currentPage = 1;
      _allData.clear(); // Use clear() instead of = []
      _filters = event.filters;
      _search = event.search;
    } else if (state is MoneyIncomeLoaded && (state as MoneyIncomeLoaded).hasReachedMax) {
      return;
    }

    try {
      if (kDebugMode) {
        print('MoneyIncomeBloc: Fetching page $_currentPage with filters: $_filters search: ${event.search}');
      }

      final response = await apiService.getMoneyIncomeDocuments(
        page: _currentPage,
        perPage: _perPage,
        filters: _filters,
        search: _search,
      );

      if (kDebugMode) {
        print('MoneyIncomeBloc: Response received');
        print('MoneyIncomeBloc: Data count: ${response.result?.data?.length ?? 0}');
      }

      final newData = response.result?.data ?? [];

      // Clear and rebuild for force refresh, append for pagination
      if (event.forceRefresh) {
        _allData = List.from(newData); // Create new list instance
      } else {
        _allData.addAll(newData);
      }

      final hasReachedMax = (response.result?.pagination?.currentPage ?? 1) >= (response.result?.pagination?.totalPages ?? 1);

      if (!hasReachedMax && newData.isNotEmpty) {
        _currentPage++;
      }

      // Always emit a new state instance
      emit(MoneyIncomeLoaded(
        data: List.from(_allData), // Create new list instance for the state
        pagination: response.result?.pagination,
        hasReachedMax: hasReachedMax,
      ));

      if (kDebugMode) {
        print('MoneyIncomeBloc: Emitted MoneyIncomeLoaded with ${_allData.length} total items, hasReachedMax: $hasReachedMax');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MoneyIncomeBloc: Error occurred: $e');
      }
      emit(MoneyIncomeError(e.toString()));
    }
  }

  Future<void> _onCreateMoneyIncome(CreateMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeCreateLoading());
    try {
      // operation types are different but api method is the same for 4 types of operations, OperationType enum is used to distinguish them
      await apiService.createMoneyIncomeDocument(
        date: event.date,
        amount: event.amount,
        operationType: event.operationType,
        movementType: event.movementType,
        leadId: event.leadId,
        senderCashRegisterId: event.senderCashRegisterId,
        cashRegisterId: event.cashRegisterId,
        comment: event.comment,
        supplierId: event.supplierId,
      );

      emit(const MoneyIncomeCreateSuccess('Документ успешно создан'));
    } catch (e) {
      emit(MoneyIncomeCreateError(e.toString()));
    }
  }

  Future<void> _onUpdateMoneyIncome(UpdateMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeUpdateLoading());
    try {
      await apiService.updateMoneyIncomeDocument(
        documentId: event.id!,
        date: event.date,
        amount: event.amount,
        operationType: event.operationType,
        movementType: event.movementType,
        leadId: event.leadId,
        senderCashRegisterId: event.senderCashRegisterId,
        cashRegisterId: event.cashRegisterId,
        comment: event.comment,
        supplierId: event.supplierId,
        approved: event.approved,
      );
      emit(const MoneyIncomeUpdateSuccess('Документ успешно обновлен'));
    } catch (e) {
      emit(MoneyIncomeUpdateError(e.toString()));
    }
  }

  Future<void> _onDeleteMoneyIncome(DeleteMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeDeleteLoading());
    try {
      final result = await apiService.deleteMoneyIncomeDocument(event.documentId);
      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(const MoneyIncomeDeleteSuccess('Документ успешно удален'));
      } else {
        emit(const MoneyIncomeDeleteError('Не удалось удалить документ'));
      }
    } catch (e) {
      emit(MoneyIncomeDeleteError('Ошибка при удалении документа: ${e.toString()}'));
    }
  }

  Future<void> _onRestoreMoneyIncome(RestoreMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeRestoreLoading());
    try {
      final result = await apiService.restoreMoneyIncomeDocument(event.documentId);
      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(const MoneyIncomeRestoreSuccess('Документ успешно восстановлен'));
      } else {
        emit(const MoneyIncomeRestoreError('Не удалось восстановить документ'));
      }
    } catch (e) {
      emit(MoneyIncomeRestoreError('Ошибка при восстановлении документа: ${e.toString()}'));
    }
  }
}