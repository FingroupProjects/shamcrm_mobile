import 'dart:async';

import 'package:crm_task_manager/models/api_exception_model.dart';
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
    on<MassApproveMoneyIncomeDocuments>(_onMassApproveMoneyIncomeDocuments);
    on<MassDisapproveMoneyIncomeDocuments>(_onMassDisapproveMoneyIncomeDocuments);
    on<MassDeleteMoneyIncomeDocuments>(_onMassDeleteMoneyIncomeDocuments);
    on<MassRestoreMoneyIncomeDocuments>(_onMassRestoreMoneyIncomeDocuments);
    on<ToggleApproveOneMoneyIncomeDocument>(_onToggleApproveOneMoneyIncomeDocument);
    on<UpdateThenToggleOneMoneyIncomeDocument>(_onUpdateThenToggleOneMoneyIncomeDocument);
    on<RemoveLocalFromList>(_onRemoveLocalFromList);
    on<SelectDocument>(_onSelectDocument);
    on<UnselectAllDocuments>(_onUnselectAllDocuments);
  }

  Future<void> _onMassApproveMoneyIncomeDocuments(MassApproveMoneyIncomeDocuments event, Emitter<MoneyIncomeState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == false && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.masApproveMoneyIncomeDocuments(ls);
      emit(MoneyIncomeApproveMassSuccess("mass_approve_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeApproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeApproveMassError(e.toString()));
      }
      add(FetchMoneyIncome(forceRefresh: true));
    }

    emit(MoneyIncomeLoaded(data: _allData));
  }

  Future<void> _onMassDisapproveMoneyIncomeDocuments(MassDisapproveMoneyIncomeDocuments event, Emitter<MoneyIncomeState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == true && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.masDisapproveMoneyIncomeDocuments(ls);
        emit(MoneyIncomeDisapproveMassSuccess("mass_disapprove_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeDisapproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeDisapproveMassError(e.toString()));
      }
      add(FetchMoneyIncome(forceRefresh: true));
    }

    emit(MoneyIncomeLoaded(data: _allData));
  }

  Future<void> _onMassDeleteMoneyIncomeDocuments(MassDeleteMoneyIncomeDocuments event, Emitter<MoneyIncomeState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.masDeleteMoneyIncomeDocuments(ls);
        emit(MoneyIncomeDeleteMassSuccess("mass_delete_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeDeleteMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeDeleteMassError(e.toString()));
      }
      add(FetchMoneyIncome(forceRefresh: true));
    }

    emit(MoneyIncomeLoaded(data: _allData));
  }

  Future<void> _onMassRestoreMoneyIncomeDocuments(MassRestoreMoneyIncomeDocuments event, Emitter<MoneyIncomeState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt != null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.masRestoreMoneyIncomeDocuments(ls);
      emit(MoneyIncomeRestoreMassSuccess("mass_restore_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeRestoreMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeRestoreMassError(e.toString()));
      }
      add(FetchMoneyIncome(forceRefresh: true));
    }

    emit(MoneyIncomeLoaded(data: _allData));
  }

  Future<void> _onToggleApproveOneMoneyIncomeDocument(ToggleApproveOneMoneyIncomeDocument event, Emitter<MoneyIncomeState> emit) async {
    try {
      await apiService.toggleApproveOneMoneyIncomeDocument(event.documentId, event.approve);
      emit(MoneyIncomeToggleOneApproveSuccess("toggle_approve_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeToggleOneApproveError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeToggleOneApproveError(e.toString()));
      }
    }

    emit(MoneyIncomeLoaded(data: _allData));
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
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeError(e.toString()));
      }
    }

    emit(MoneyIncomeLoaded(data: _allData));
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
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeCreateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeCreateError(e.toString()));
      }
    }

    emit(MoneyIncomeLoaded(data: _allData));
  }

  Future<void> _onUpdateMoneyIncome(UpdateMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeLoading());
    // use the same on UpdateThenToggleOneMoneyIncomeDocument
    try {
      final response = await apiService.updateMoneyIncomeDocument(
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
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeUpdateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeUpdateError(e.toString()));
      }
    }

    emit(MoneyIncomeLoaded(data: _allData));
  }

  Future<void> _onUpdateThenToggleOneMoneyIncomeDocument(UpdateThenToggleOneMoneyIncomeDocument event, Emitter<MoneyIncomeState> emit) async {
    // send two requests, first update, then toggle approve
    bool firstFailed = false;

    // use the same on UpdateMoneyIncome
    // first update
    try {
      final response = await apiService.updateMoneyIncomeDocument(
        documentId: event.id,
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
    } catch (e) {
      firstFailed = true;
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeUpdateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeUpdateError(e.toString()));
      }
    }

    // send only if first succeeded
    if (firstFailed) {
      emit(MoneyIncomeLoaded(data: _allData));
      return;
    }

    await Future.delayed(const Duration(milliseconds: 2000));

    // then toggle approve
    try {
      await apiService.toggleApproveOneMoneyIncomeDocument(event.id, event.approve);
      // emit(const MoneyIncomeUpdateSuccess('document_updated_successfully'));
      // emit(MoneyIncomeToggleOneApproveSuccess("toggle_approve_success_message"));
      emit(MoneyIncomeUpdateThenToggleOneApproveSuccess("document_updated_and_approve_toggled_successfully"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeToggleOneApproveError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeToggleOneApproveError(e.toString()));
      }
    }

    emit(MoneyIncomeLoaded(data: _allData));
  }

  // only by swiping
  Future<void> _onDeleteMoneyIncome(DeleteMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    bool failed = false;

    // if (event.reload) emit(MoneyIncomeLoading());
    try {
      final result = await apiService.deleteMoneyIncomeDocument(event.document.id!);
      if (result) {
        // if (event.reload) emit(MoneyIncomeDeleteSuccess('document_deleted_successfully', reload: event.reload));
        // if (event.reload) add(RemoveLocalFromList(event.document.id!));
      }/* else {
        emit(const MoneyIncomeDeleteError('failed_to_delete_document'));
        failed = true;
      }*/
      emit(MoneyIncomeDeleteSuccess('document_deleted_successfully', reload: true));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeDeleteError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeDeleteError(e.toString()));
      }
      failed = true;
    }

    if (failed) {
      add(FetchMoneyIncome(forceRefresh: true));
    } else {
      emit(MoneyIncomeLoaded(data: _allData));
    }
  }

  Future<void> _onRestoreMoneyIncome(RestoreMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeLoading());

    try {
      await apiService.masRestoreMoneyIncomeDocuments([event.documentId]);
      emit(MoneyIncomeRestoreMassSuccess("mass_restore_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeRestoreMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeRestoreMassError(e.toString()));
      }
      add(FetchMoneyIncome(forceRefresh: true));
    }

    emit(MoneyIncomeLoaded(data: _allData));
  }

  /// LOCAL LIST MANAGEMENT WITHOUT API CALLS

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

