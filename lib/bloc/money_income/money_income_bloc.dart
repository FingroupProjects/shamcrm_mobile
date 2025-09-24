import 'dart:async';

import 'package:crm_task_manager/models/money/money_income_document_model.dart';
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
  Set<Document> _selectedDocuments = {};

  MoneyIncomeBloc() : super(MoneyIncomeInitial()) {
    on<FetchMoneyIncome>(_onFetchMoneyIncome);
    on<CreateMoneyIncome>(_onCreateMoneyIncome);
    on<UpdateMoneyIncome>(_onUpdateMoneyIncome);
    on<DeleteMoneyIncome>(_onDeleteMoneyIncome);
    on<RestoreMoneyIncome>(_onRestoreMoneyIncome);
    on<AddMoneyIncome>(_onAddMoneyIncome);
    on<MassApproveMoneyIncomeDocuments>(_onMassApproveMoneyIncomeDocuments);
    on<MassDisapproveMoneyIncomeDocuments>(_onMassDisapproveMoneyIncomeDocuments);
    on<MassDeleteMoneyIncomeDocuments>(_onMassDeleteMoneyIncomeDocuments);
    on<MassRestoreMoneyIncomeDocuments>(_onMassRestoreMoneyIncomeDocuments);
    on<ToggleApproveOneMoneyIncomeDocument>(_onToggleApproveOneMoneyIncomeDocument);
    on<RemoveLocalFromList>(_onRemoveLocalFromList);
    on<SelectDocument>(_onSelectDocument);
    on<UnselectAllDocuments>(_onUnselectAllDocuments);
  }

  Future<void> _onMassApproveMoneyIncomeDocuments(MassApproveMoneyIncomeDocuments event, Emitter<MoneyIncomeState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == false && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    final response = await apiService.masApproveMoneyIncomeDocuments(ls);
    try {
      emit(MoneyIncomeApproveMassSuccess(""));
    } catch (e) {
      emit(MoneyIncomeToggleOneApproveError(e.toString()));
    }
  }

  Future<void> _onMassDisapproveMoneyIncomeDocuments(MassDisapproveMoneyIncomeDocuments event, Emitter<MoneyIncomeState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == true && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      final response = await apiService.masDisapproveMoneyIncomeDocuments(ls);
        emit(MoneyIncomeDisapproveMassSuccess("Подтверждение отменено"));
    } catch (e) {
      emit(MoneyIncomeDisapproveMassError(e.toString()));
    }
  }

  Future<void> _onMassDeleteMoneyIncomeDocuments(MassDeleteMoneyIncomeDocuments event, Emitter<MoneyIncomeState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      final response = await apiService.masDeleteMoneyIncomeDocuments(ls);
        emit(MoneyIncomeDeleteMassSuccess("Документы удалены"));
    } catch (e) {
      emit(MoneyIncomeDeleteMassError(e.toString()));
    }
  }

  Future<void> _onMassRestoreMoneyIncomeDocuments(MassRestoreMoneyIncomeDocuments event, Emitter<MoneyIncomeState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt != null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      final response = await apiService.masRestoreMoneyIncomeDocuments(ls);
        emit(MoneyIncomeRestoreMassSuccess("Документы восстановлены"));
    } catch (e) {
      emit(MoneyIncomeRestoreMassError(e.toString()));
    }
  }

  Future<void> _onToggleApproveOneMoneyIncomeDocument(ToggleApproveOneMoneyIncomeDocument event, Emitter<MoneyIncomeState> emit) async {
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

      final selectedDocuments = _allData
          .where((doc) => _selectedDocuments.contains(doc))
          .toList();

      emit(MoneyIncomeLoaded(
        data: List.from(_allData),
        pagination: response.result?.pagination,
        hasReachedMax: hasReachedMax,
        selectedData: selectedDocuments,
      ));
    } catch (e) {
      emit(MoneyIncomeError(e.toString()));
    }
  }

  Future<void> _onCreateMoneyIncome(CreateMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeLoading());
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
        approve: event.approve,
      );

      emit(const MoneyIncomeCreateSuccess('document_created_successfully'));
    } catch (e) {
      emit(MoneyIncomeCreateError(e.toString()));
    }
  }

  Future<void> _onUpdateMoneyIncome(UpdateMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeLoading());
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
    if (event.reload) emit(MoneyIncomeLoading());
    try {
      final result = await apiService.deleteMoneyIncomeDocument(event.documentId);
      if (result) {
        if (event.reload) emit(MoneyIncomeDeleteSuccess('document_deleted_successfully', reload: event.reload));
        if (event.reload) add(RemoveLocalFromList(event.documentId));
      } else {
        emit(const MoneyIncomeDeleteError('failed_to_delete_document'));
      }
    } catch (e) {
      emit(MoneyIncomeDeleteError(e.toString()));
    }
  }

  Future<void> _onRestoreMoneyIncome(RestoreMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeLoading());
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
    emit(MoneyIncomeLoading());
    final double remainingPercentage = _allData.length / _perPage;
    if (remainingPercentage < 0.3) {
      add(FetchMoneyIncome(forceRefresh: true));
    } else {
      _allData.removeWhere((doc) => doc.id == event.documentId);
      emit(MoneyIncomeLoaded(
        data: List.from(_allData),
        pagination: null,
        hasReachedMax: false,
      ));
    }
  }

  Future<void> _onSelectDocument(SelectDocument event, Emitter<MoneyIncomeState> emit) async {
    if (state is MoneyIncomeLoaded) {
      final currentState = state as MoneyIncomeLoaded;

      if (_selectedDocuments.contains(event.document)) {
        _selectedDocuments.remove(event.document);
      } else {
        _selectedDocuments.add(event.document);
      }

      final selectedDocuments = currentState.data
          .where((doc) => _selectedDocuments.contains(doc))
          .toList();

      emit(MoneyIncomeLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: selectedDocuments,
      ));
    }
  }

  Future<void> _onUnselectAllDocuments(UnselectAllDocuments event, Emitter<MoneyIncomeState> emit) async {
    _selectedDocuments = {};

    if (state is MoneyIncomeLoaded) {
      final currentState = state as MoneyIncomeLoaded;
      emit(MoneyIncomeLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: [],
      ));
    }
  }
}

