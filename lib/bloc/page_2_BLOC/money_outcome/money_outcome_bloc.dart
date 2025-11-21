import 'dart:async';

import 'package:crm_task_manager/models/api_exception_model.dart';
import 'package:crm_task_manager/models/money/money_outcome_document_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

part 'money_outcome_event.dart';

part 'money_outcome_state.dart';

class MoneyOutcomeBloc extends Bloc<MoneyOutcomeEvent, MoneyOutcomeState> {
  final ApiService apiService = ApiService();
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic>? _filters;
  String? _search = '';
  List<Document> _allData = [];
  Set<Document> _selectedDocuments = {};

  MoneyOutcomeBloc() : super(MoneyOutcomeInitial()) {
    on<FetchMoneyOutcome>(_onFetchMoneyOutcome);
    on<CreateMoneyOutcome>(_onCreateMoneyOutcome);
    on<UpdateMoneyOutcome>(_onUpdateMoneyOutcome);
    on<DeleteMoneyOutcome>(_onDeleteMoneyOutcome);
    on<RestoreMoneyOutcome>(_onRestoreMoneyOutcome);
    on<MassApproveMoneyOutcomeDocuments>(_onMassApproveMoneyOutcomeDocuments);
    on<MassDisapproveMoneyOutcomeDocuments>(_onMassDisapproveMoneyOutcomeDocuments);
    on<MassDeleteMoneyOutcomeDocuments>(_onMassDeleteMoneyOutcomeDocuments);
    on<MassRestoreMoneyOutcomeDocuments>(_onMassRestoreMoneyOutcomeDocuments);
    on<ToggleApproveOneMoneyOutcomeDocument>(_onToggleApproveOneMoneyOutcomeDocument);
    on<UpdateThenToggleOneMoneyOutcomeDocument>(_onUpdateThenToggleOneMoneyOutcomeDocument);
    on<RemoveLocalFromList>(_onRemoveLocalFromList);
    on<SelectDocument>(_onSelectDocument);
    on<UnselectAllDocuments>(_onUnselectAllDocuments);
  }

  Future<void> _onMassApproveMoneyOutcomeDocuments(MassApproveMoneyOutcomeDocuments event, Emitter<MoneyOutcomeState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == false && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.masApproveMoneyOutcomeDocuments(ls);
      emit(MoneyOutcomeApproveMassSuccess("mass_approve_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyOutcomeApproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyOutcomeApproveMassError(e.toString()));
      }
      add(FetchMoneyOutcome(forceRefresh: true));
    }
  }

  Future<void> _onMassDisapproveMoneyOutcomeDocuments(MassDisapproveMoneyOutcomeDocuments event, Emitter<MoneyOutcomeState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == true && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.masDisapproveMoneyOutcomeDocuments(ls);
      emit(MoneyOutcomeDisapproveMassSuccess("mass_disapprove_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyOutcomeDisapproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyOutcomeDisapproveMassError(e.toString()));
      }
      add(FetchMoneyOutcome(forceRefresh: true));
    }
  }

  Future<void> _onMassDeleteMoneyOutcomeDocuments(MassDeleteMoneyOutcomeDocuments event, Emitter<MoneyOutcomeState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.masDeleteMoneyOutcomeDocuments(ls);
      emit(MoneyOutcomeDeleteMassSuccess("mass_delete_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyOutcomeDeleteMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyOutcomeDeleteMassError(e.toString()));
      }
      add(FetchMoneyOutcome(forceRefresh: true));
    }
  }

  Future<void> _onMassRestoreMoneyOutcomeDocuments(MassRestoreMoneyOutcomeDocuments event, Emitter<MoneyOutcomeState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt != null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.masRestoreMoneyOutcomeDocuments(ls);
      emit(MoneyOutcomeRestoreMassSuccess("mass_restore_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyOutcomeRestoreMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyOutcomeRestoreMassError(e.toString()));
      }
      add(FetchMoneyOutcome(forceRefresh: true));
    }
  }

  Future<void> _onToggleApproveOneMoneyOutcomeDocument(ToggleApproveOneMoneyOutcomeDocument event, Emitter<MoneyOutcomeState> emit) async {
    try {
      await apiService.toggleApproveOneMoneyOutcomeDocument(event.documentId, event.approve);
      emit(MoneyOutcomeToggleOneApproveSuccess("toggle_approve_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyOutcomeToggleOneApproveError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyOutcomeToggleOneApproveError(e.toString()));
      }
    }
  }

  Future<void> _onFetchMoneyOutcome(FetchMoneyOutcome event, Emitter<MoneyOutcomeState> emit) async {
    if (event.forceRefresh || _allData.isEmpty) {
      emit(MoneyOutcomeLoading());
    }

    if (event.forceRefresh) {
      _currentPage = 1;
      _allData.clear();
      _filters = event.filters;
      _search = event.search;
    } else if (state is MoneyOutcomeLoaded && (state as MoneyOutcomeLoaded).hasReachedMax) {
      return;
    }

    try {
      final response = await apiService.getMoneyOutcomeDocuments(
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

      emit(MoneyOutcomeLoaded(
        data: List.from(_allData),
        pagination: response.result?.pagination,
        hasReachedMax: hasReachedMax,
        selectedData: selectedDocuments,
      ));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyOutcomeError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyOutcomeError(e.toString()));
      }
    }
  }

  Future<void> _onCreateMoneyOutcome(CreateMoneyOutcome event, Emitter<MoneyOutcomeState> emit) async {
    emit(MoneyOutcomeLoading());
    try {
      await apiService.createMoneyOutcomeDocument(
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

      emit(const MoneyOutcomeCreateSuccess('document_created_successfully'));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyOutcomeCreateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyOutcomeCreateError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateMoneyOutcome(UpdateMoneyOutcome event, Emitter<MoneyOutcomeState> emit) async {
    emit(MoneyOutcomeLoading());
    // use the same on UpdateThenToggleOneMoneyOutcomeDocument
    try {
      await apiService.updateMoneyOutcomeDocument(
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
      emit(const MoneyOutcomeUpdateSuccess('document_updated_successfully'));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyOutcomeUpdateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyOutcomeUpdateError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateThenToggleOneMoneyOutcomeDocument(UpdateThenToggleOneMoneyOutcomeDocument event, Emitter<MoneyOutcomeState> emit) async {
    // send two requests, first update, then toggle approve
    bool firstFailed = false;

    // use the same on UpdateMoneyOutcome
    // first update
    try {
      await apiService.updateMoneyOutcomeDocument(
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
        emit(MoneyOutcomeUpdateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyOutcomeUpdateError(e.toString()));
      }
    }

    // send only if first succeeded
    if (firstFailed) {
      emit(MoneyOutcomeLoaded(data: _allData));
      return;
    }

    await Future.delayed(const Duration(milliseconds: 2000));

    // then toggle approve
    try {
      await apiService.toggleApproveOneMoneyOutcomeDocument(event.id, event.approve);
      // emit(const MoneyOutcomeUpdateSuccess('document_updated_successfully'));
      // emit(MoneyOutcomeToggleOneApproveSuccess("toggle_approve_success_message"));
      emit(MoneyOutcomeUpdateThenToggleOneApproveSuccess("document_updated_and_approve_toggled_successfully"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyOutcomeToggleOneApproveError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyOutcomeToggleOneApproveError(e.toString()));
      }
    }
  }

  // only by swiping
  Future<void> _onDeleteMoneyOutcome(DeleteMoneyOutcome event, Emitter<MoneyOutcomeState> emit) async {
    bool failed = false;

    // if (event.reload) emit(MoneyOutcomeLoading());
    try {
      final result = await apiService.deleteMoneyOutcomeDocument(event.document.id!);
      if (result) {
        // if (event.reload) emit(MoneyOutcomeDeleteSuccess('document_deleted_successfully', reload: event.reload));
        // if (event.reload) add(RemoveLocalFromList(event.document.id!));
      }/* else {
        emit(const MoneyOutcomeDeleteError('failed_to_delete_document'));
        failed = true;
      }*/
      emit(const MoneyOutcomeDeleteSuccess('document_deleted_successfully', reload: true));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyOutcomeDeleteError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyOutcomeDeleteError(e.toString()));
      }
      failed = true;
    }

    if (failed) {
      add(FetchMoneyOutcome(forceRefresh: true));
    } else {
      emit(MoneyOutcomeLoaded(data: _allData));
    }
  }

  Future<void> _onRestoreMoneyOutcome(RestoreMoneyOutcome event, Emitter<MoneyOutcomeState> emit) async {
    emit(MoneyOutcomeLoading());

    try {
      await apiService.masRestoreMoneyOutcomeDocuments([event.documentId]);
      emit(MoneyOutcomeRestoreMassSuccess("mass_restore_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyOutcomeRestoreMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MoneyOutcomeRestoreMassError(e.toString()));
      }
      add(FetchMoneyOutcome(forceRefresh: true));
    }
  }

  /// LOCAL LIST MANAGEMENT WITHOUT API CALLS

  Future<void> _onRemoveLocalFromList(RemoveLocalFromList event, Emitter<MoneyOutcomeState> emit) async {
    emit(MoneyOutcomeLoading());
    final double remainingPercentage = _allData.length / _perPage;

    if (remainingPercentage < 0.3) {
      add(FetchMoneyOutcome(forceRefresh: true));
    } else {
      _allData.removeWhere((doc) => doc.id == event.documentId);
      emit(MoneyOutcomeLoaded(
        data: List.from(_allData),
        pagination: null,
        hasReachedMax: false,
      ));
    }
  }

  Future<void> _onSelectDocument(SelectDocument event, Emitter<MoneyOutcomeState> emit) async {
    if (state is MoneyOutcomeLoaded) {
      final currentState = state as MoneyOutcomeLoaded;

      if (_selectedDocuments.contains(event.document)) {
        _selectedDocuments.remove(event.document);
      } else {
        _selectedDocuments.add(event.document);
      }

      final selectedDocuments = currentState.data
          .where((doc) => _selectedDocuments.contains(doc))
          .toList();

      emit(MoneyOutcomeLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: selectedDocuments,
      ));
    }
  }

  Future<void> _onUnselectAllDocuments(UnselectAllDocuments event, Emitter<MoneyOutcomeState> emit) async {
    _selectedDocuments = {};

    if (state is MoneyOutcomeLoaded) {
      final currentState = state as MoneyOutcomeLoaded;
      emit(MoneyOutcomeLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: [],
      ));
    }
  }
}

