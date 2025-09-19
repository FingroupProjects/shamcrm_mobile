import 'dart:async';

import 'package:crm_task_manager/models/money/money_outcome_document_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter/foundation.dart';

part 'money_outcome_event.dart';
part 'money_outcome_state.dart';

class MoneyOutcomeBloc extends Bloc<MoneyOutcomeEvent, MoneyOutcomeState> {
  final ApiService apiService = ApiService();
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic>? _filters;
  String? _search = '';
  List<Document> _allData = [];


  MoneyOutcomeBloc() : super(MoneyOutcomeInitial()) {
    on<FetchMoneyOutcome>(_onFetchMoneyOutcome);
    on<CreateMoneyOutcome>(_onCreateMoneyOutcome);
    on<UpdateMoneyOutcome>(_onUpdateMoneyOutcome);
    on<DeleteMoneyOutcome>(_onDeleteMoneyOutcome);
    on<RestoreMoneyOutcome>(_onRestoreMoneyOutcome);
    on<AddMoneyOutcome>(_onAddMoneyOutcome);
  }

  Future<void> _onAddMoneyOutcome(AddMoneyOutcome event, Emitter<MoneyOutcomeState> emit) async {
    emit(MoneyOutcomeNavigateToAdd());
  }

  Future<void> _onFetchMoneyOutcome(FetchMoneyOutcome event, Emitter<MoneyOutcomeState> emit) async {
    if (event.forceRefresh) {
      _currentPage = 1;
      _allData = [];
      _filters = event.filters;
      _search = event.search;
      emit(MoneyOutcomeLoading());
    } else if (state is MoneyOutcomeLoaded && (state as MoneyOutcomeLoaded).hasReachedMax) {
      return;
    }

    try {
      if (kDebugMode) {
        print('MoneyOutcomeBloc: Fetching page $_currentPage with filters: $_filters search: ${event.search}');
      }

      final response = await apiService.getMoneyOutcomeDocuments(
        page: _currentPage,
        perPage: _perPage,
        filters: _filters,
        search: _search,
      );

      if (kDebugMode) {
        print('MoneyOutcomeBloc: Response received');
        print('MoneyOutcomeBloc: Data count: ${response.result?.data?.length ?? 0}');
      }

      final newData = response.result?.data ?? [];
      _allData = event.forceRefresh ? newData : [..._allData, ...newData];

      final hasReachedMax = (response.result?.pagination?.currentPage ?? 1) >= (response.result?.pagination?.totalPages ?? 1);

      if (!hasReachedMax && newData.isNotEmpty) {
        _currentPage++;
      }

      emit(MoneyOutcomeLoaded(
        data: _allData,
        pagination: response.result?.pagination,
        hasReachedMax: hasReachedMax,
      ));

      if (kDebugMode) {
        print('MoneyOutcomeBloc: Emitted MoneyOutcomeLoaded with ${_allData.length} total items, hasReachedMax: $hasReachedMax');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MoneyOutcomeBloc: Error occurred: $e');
      }
      emit(MoneyOutcomeError(e.toString()));
    }
  }

  Future<void> _onCreateMoneyOutcome(CreateMoneyOutcome event, Emitter<MoneyOutcomeState> emit) async {
    emit(MoneyOutcomeCreateLoading());
    try {
      // operation types are different but api method is the same for 4 types of operations, OperationType enum is used to distinguish them
      await apiService.createMoneyOutcomeDocument(
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

      emit(const MoneyOutcomeCreateSuccess('Документ успешно создан'));
    } catch (e) {
      emit(MoneyOutcomeCreateError(e.toString()));
    }
  }

  Future<void> _onUpdateMoneyOutcome(UpdateMoneyOutcome event, Emitter<MoneyOutcomeState> emit) async {
    emit(MoneyOutcomeUpdateLoading());
    try {
      await apiService.updateMoneyOutcomeDocument(
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
      emit(const MoneyOutcomeUpdateSuccess('Документ успешно обновлен'));
    } catch (e) {
      emit(MoneyOutcomeUpdateError(e.toString()));
    }
  }

  Future<void> _onDeleteMoneyOutcome(DeleteMoneyOutcome event, Emitter<MoneyOutcomeState> emit) async {
    emit(MoneyOutcomeDeleteLoading());
    try {
      final result = await apiService.deleteMoneyOutcomeDocument(event.documentId);
      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(const MoneyOutcomeDeleteSuccess('Документ успешно удален'));
      } else {
        emit(const MoneyOutcomeDeleteError('Не удалось удалить документ'));
      }
    } catch (e) {
      emit(MoneyOutcomeDeleteError('Ошибка при удалении документа: ${e.toString()}'));
    }
  }

  Future<void> _onRestoreMoneyOutcome(RestoreMoneyOutcome event, Emitter<MoneyOutcomeState> emit) async {
    emit(MoneyOutcomeRestoreLoading());
    try {
      final result = await apiService.restoreMoneyOutcomeDocument(event.documentId);
      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(const MoneyOutcomeRestoreSuccess('Документ успешно восстановлен'));
      } else {
        emit(const MoneyOutcomeRestoreError('Не удалось восстановить документ'));
      }
    } catch (e) {
      emit(MoneyOutcomeRestoreError('Ошибка при восстановлении документа: ${e.toString()}'));
    }
  }
}