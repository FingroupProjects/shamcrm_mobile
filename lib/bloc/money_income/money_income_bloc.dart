import 'dart:async';

import 'package:crm_task_manager/models/money/money_income_document_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

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
    // on<MassApproveMoneyIncomeDocuments>(_onMassApproveMoneyIncomeDocuments);
    on<ToggleApproveOneMoneyIncomeDocument>(_onToggleApproveOneMoneyIncomeDocument);
    on<RemoveLocalFromList>(_onRemoveLocalFromList);
  }

  // Future<void> _onMassApproveMoneyIncomeDocuments(MassApproveMoneyIncomeDocuments event, Emitter<MoneyIncomeState> emit) async {
  //   final allApproved = await apiService.masApproveMoneyIncomeDocuments(event.documentIds);
  //
  //   if (allApproved) {
  //     emit(MoneyIncomeApproveMassSuccess(""));
  //   } else {
  //     emit(MoneyIncomeApproveMassError("approve_mass_error"));
  //   }
  // }

  Future<void> _onToggleApproveOneMoneyIncomeDocument(
      ToggleApproveOneMoneyIncomeDocument event, Emitter<MoneyIncomeState> emit) async {
    try {
      final approved = await apiService.toggleApproveOneMoneyIncomeDocument(event.documentId, event.approve);
      if (approved) {
        emit(MoneyIncomeToggleOneApproveSuccess(""));
      } else {
        emit(MoneyIncomeToggleOneApproveError("approve_error"));
      }
    } catch (e) {
      emit(MoneyIncomeToggleOneApproveError(e.toString()));
    }
  }

  Future<void> _onAddMoneyIncome(AddMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeNavigateToAdd());
  }

  Future<void> _onFetchMoneyIncome(FetchMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    if (event.forceRefresh || _allData.isEmpty) {
      emit(MoneyIncomeLoading());
    }

    if (event.forceRefresh) {
      _currentPage = 1;
      _allData.clear();
      _filters = event.filters;
      _search = event.search;
    } else if (state is MoneyIncomeLoaded && (state as MoneyIncomeLoaded).hasReachedMax) {
      return;
    }

    try {
      final response = await apiService.getMoneyIncomeDocuments(
        page: _currentPage,
        perPage: _perPage,
        filters: _filters,
        search: _search,
      );

      final newData = response.result?.data ?? [];

      if (event.forceRefresh) {
        _allData = List.from(newData);
      } else {
        _allData.addAll(newData);
      }

      final hasReachedMax = (response.result?.pagination?.currentPage ?? 1) >= (response.result?.pagination?.totalPages ?? 1);

      if (!hasReachedMax && newData.isNotEmpty) {
        _currentPage++;
      }

      emit(MoneyIncomeLoaded(
        data: List.from(_allData),
        pagination: response.result?.pagination,
        hasReachedMax: hasReachedMax,
      ));
    } catch (e) {
      emit(MoneyIncomeError(e.toString()));
    }
  }

  Future<void> _onCreateMoneyIncome(CreateMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeCreateLoading());
    try {
      await apiService.createMoneyIncomeDocument(
        date: event.date,
        amount: event.amount,
        operationType: event.operationType,
        movementType: event.movementType,
        leadId: event.leadId,
        articleId: event.articleId,
        senderCashRegisterId: event.senderCashRegisterId,
        cashRegisterId: event.cashRegisterId,
        comment: event.comment,
        supplierId: event.supplierId,
      );

      emit(const MoneyIncomeCreateSuccess('document_created_successfully'));
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
        articleId: event.articleId,
        senderCashRegisterId: event.senderCashRegisterId,
        cashRegisterId: event.cashRegisterId,
        comment: event.comment,
        supplierId: event.supplierId,
      );
      emit(const MoneyIncomeUpdateSuccess('document_updated_successfully'));
    } catch (e) {
      emit(MoneyIncomeUpdateError(e.toString()));
    }
  }

  Future<void> _onDeleteMoneyIncome(DeleteMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeDeleteLoading());
    await Future.delayed(const Duration(seconds: 5));
    try {
      final result = await apiService.deleteMoneyIncomeDocument(event.documentId);
      if (result) {
        emit(const MoneyIncomeDeleteSuccess('document_deleted_successfully'));
        add(RemoveLocalFromList(event.documentId));
      } else {
        emit(const MoneyIncomeDeleteError('failed_to_delete_document'));
      }
    } catch (e) {
      emit(MoneyIncomeDeleteError(e.toString()));
    }
  }

  Future<void> _onRestoreMoneyIncome(RestoreMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeRestoreLoading());
    try {
      final result = await apiService.restoreMoneyIncomeDocument(event.documentId);
      if (result['result'] == 'Success') {
        emit(const MoneyIncomeRestoreSuccess('document_restored_successfully'));
      } else {
        emit(const MoneyIncomeRestoreError('failed_to_restore_document'));
      }
    } catch (e) {
      emit(MoneyIncomeRestoreError('error_restoring_document: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveLocalFromList(RemoveLocalFromList event, Emitter<MoneyIncomeState> emit) async {
    // Проверяем процент оставшихся
    // Если удалено >= 30%, сразу подгружаем новые данные с сервера (форсированно) иначе просто удаляем из локального списка

    final deletedPercent = 1 - (_allData.length / (_perPage));
    if (deletedPercent >= 0.3) {
      debugPrint('Force refresh due to high deletion percentage: $deletedPercent');
      add(FetchMoneyIncome(forceRefresh: true));
    } else {
      debugPrint('Local removal, deletion percentage: $deletedPercent');
      _allData.removeWhere((doc) => doc.id == event.documentId);
      emit(MoneyIncomeLoaded(
        data: List.from(_allData),
        pagination: null,
        hasReachedMax: false,
      ));
    }
  }
}