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
  Map<String, dynamic> _filters = {};
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
    if (event.forceRefresh) {
      _currentPage = 1;
      _allData = [];
      _filters = event.filters ?? {};
      emit(MoneyIncomeLoading());
    } else if (state is MoneyIncomeLoaded && (state as MoneyIncomeLoaded).hasReachedMax) {
      return;
    }

    try {
      if (kDebugMode) {
        print('MoneyIncomeBloc: Fetching page $_currentPage with filters: $_filters');
      }

      final response = await apiService.getMoneyIncomeDocuments(
        page: _currentPage,
        perPage: _perPage,
        query: _filters['query'],
        fromDate: _filters['fromDate'],
        toDate: _filters['toDate'],
      );

      if (kDebugMode) {
        print('MoneyIncomeBloc: Response received');
        print('MoneyIncomeBloc: Data count: ${response.result?.data?.length ?? 0}');
      }

      // Handle the response structure similar to IncomingBloc
      final newData = response.result?.data ?? [];
      _allData = event.forceRefresh ? newData : [..._allData, ...newData];

      // Handle pagination similar to IncomingBloc
      final hasReachedMax = (response.result?.pagination?.currentPage ?? 1) >= (response.result?.pagination?.totalPages ?? 1);

      if (!hasReachedMax && newData.isNotEmpty) {
        _currentPage++;
      }

      emit(MoneyIncomeLoaded(
        data: _allData,
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
      );

      await Future.delayed(const Duration(milliseconds: 100));
      emit(const MoneyIncomeCreateSuccess('Документ успешно создан'));
    } catch (e) {
      emit(MoneyIncomeCreateError(e.toString()));
    }
  }

  Future<void> _onUpdateMoneyIncome(UpdateMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeUpdateLoading());
    // try {
    //   await apiService.updateMoneyIncomeDocument(
    //     documentId: event.documentId,
    //     date: event.date,
    //     storageId: event.storageId,
    //     comment: event.comment,
    //     counterpartyId: event.counterpartyId,
    //     documentGoods: event.documentGoods,
    //     organizationId: event.organizationId,
    //     salesFunnelId: event.salesFunnelId,
    //     amount: event.amount,
    //     description: event.description,
    //   );
    //
    //   await Future.delayed(const Duration(milliseconds: 100));
    //   emit(const MoneyIncomeUpdateSuccess('Документ успешно обновлен'));
    // } catch (e) {
    //   emit(MoneyIncomeUpdateError(e.toString()));
    // }
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