import 'dart:async';
import 'package:crm_task_manager/utils/document_date_period.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';

import 'package:crm_task_manager/models/common/api_exception_model.dart';
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
  // Итого как в продажах. Показываем только на двух поддоменах.
  double? _totalSum;
  DocumentDatePeriod _datePeriod = DocumentDatePeriod.today;
  bool _showTotal = false;

  MoneyIncomeBloc() : super(MoneyIncomeInitial()) {
    on<FetchMoneyIncome>(_onFetchMoneyIncome);
    on<CreateMoneyIncome>(_onCreateMoneyIncome);
    on<UpdateMoneyIncome>(_onUpdateMoneyIncome);
    on<DeleteMoneyIncome>(_onDeleteMoneyIncome);
    on<RestoreMoneyIncome>(_onRestoreMoneyIncome);
    on<MassApproveMoneyIncomeDocuments>(_onMassApproveMoneyIncomeDocuments);
    on<MassDisapproveMoneyIncomeDocuments>(
        _onMassDisapproveMoneyIncomeDocuments);
    on<MassDeleteMoneyIncomeDocuments>(_onMassDeleteMoneyIncomeDocuments);
    on<MassRestoreMoneyIncomeDocuments>(_onMassRestoreMoneyIncomeDocuments);
    on<ToggleApproveOneMoneyIncomeDocument>(
        _onToggleApproveOneMoneyIncomeDocument);
    on<UpdateThenToggleOneMoneyIncomeDocument>(
        _onUpdateThenToggleOneMoneyIncomeDocument);
    on<RemoveLocalFromList>(_onRemoveLocalFromList);
    on<SelectDocument>(_onSelectDocument);
    on<UnselectAllDocuments>(_onUnselectAllDocuments);
  }

  Future<void> _onMassApproveMoneyIncomeDocuments(
      MassApproveMoneyIncomeDocuments event,
      Emitter<MoneyIncomeState> emit) async {
    final ls = _selectedDocuments
        .where((e) => e.approved == false && e.deletedAt == null)
        .map((e) => e.id!)
        .toList();
    add(UnselectAllDocuments());

    try {
      await apiService.masApproveMoneyIncomeDocuments(ls);
      emit(MoneyIncomeApproveMassSuccess("mass_approve_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeApproveMassError(friendlyError(e),
            statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeApproveMassError(friendlyError(e)));
      }
      add(FetchMoneyIncome(forceRefresh: true));
    }
  }

  Future<void> _onMassDisapproveMoneyIncomeDocuments(
      MassDisapproveMoneyIncomeDocuments event,
      Emitter<MoneyIncomeState> emit) async {
    final ls = _selectedDocuments
        .where((e) => e.approved == true && e.deletedAt == null)
        .map((e) => e.id!)
        .toList();
    add(UnselectAllDocuments());

    try {
      await apiService.masDisapproveMoneyIncomeDocuments(ls);
      emit(MoneyIncomeDisapproveMassSuccess("mass_disapprove_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeDisapproveMassError(friendlyError(e),
            statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeDisapproveMassError(friendlyError(e)));
      }
      add(FetchMoneyIncome(forceRefresh: true));
    }
  }

  Future<void> _onMassDeleteMoneyIncomeDocuments(
      MassDeleteMoneyIncomeDocuments event,
      Emitter<MoneyIncomeState> emit) async {
    final ls = _selectedDocuments
        .where((e) => e.deletedAt == null)
        .map((e) => e.id!)
        .toList();
    add(UnselectAllDocuments());

    try {
      await apiService.masDeleteMoneyIncomeDocuments(ls);
      emit(MoneyIncomeDeleteMassSuccess("mass_delete_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(
            MoneyIncomeDeleteMassError(friendlyError(e), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeDeleteMassError(friendlyError(e)));
      }
      add(FetchMoneyIncome(forceRefresh: true));
    }
  }

  Future<void> _onMassRestoreMoneyIncomeDocuments(
      MassRestoreMoneyIncomeDocuments event,
      Emitter<MoneyIncomeState> emit) async {
    final ls = _selectedDocuments
        .where((e) => e.deletedAt != null)
        .map((e) => e.id!)
        .toList();
    add(UnselectAllDocuments());

    try {
      await apiService.masRestoreMoneyIncomeDocuments(ls);
      emit(MoneyIncomeRestoreMassSuccess("mass_restore_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeRestoreMassError(friendlyError(e),
            statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeRestoreMassError(friendlyError(e)));
      }
      add(FetchMoneyIncome(forceRefresh: true));
    }
  }

  Future<void> _onToggleApproveOneMoneyIncomeDocument(
      ToggleApproveOneMoneyIncomeDocument event,
      Emitter<MoneyIncomeState> emit) async {
    try {
      await apiService.toggleApproveOneMoneyIncomeDocument(
          event.documentId, event.approve);
      emit(
          MoneyIncomeToggleOneApproveSuccess("toggle_approve_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeToggleOneApproveError(friendlyError(e),
            statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeToggleOneApproveError(friendlyError(e)));
      }
    }
  }

  Future<void> _onFetchMoneyIncome(
      FetchMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    if (event.forceRefresh || _allData.isEmpty) {
      emit(MoneyIncomeLoading());
    }

    if (event.forceRefresh) {
      _currentPage = 1;
      _allData.clear();
      _filters = event.filters;
      _search = event.search;
    } else if (state is MoneyIncomeLoaded &&
        (state as MoneyIncomeLoaded).hasReachedMax) {
      return;
    }

    try {
      // Итого грузим только на разрешённых доменах и только при полном refresh.
      _showTotal = await apiService.supportsCheckingAccountSum();
      final dateFilter = DocumentDatePeriodX.resolveFromFilters(_filters);
      _datePeriod = dateFilter.period;
      final approved = _intFilter('approved');
      final deleted = _intFilter('deleted');
      final leadId = _intFilter('lead_id');
      final cashRegisterId =
          _intFilter('cash_register_id') ?? _intFilter('storage_id');
      final supplierId = _intFilter('supplier_id');
      final authorId = _intFilter('author_id');

      final listFuture = apiService.getMoneyIncomeDocuments(
        page: _currentPage,
        perPage: _perPage,
        filters: _filters,
        search: _search,
      );
      final sumFuture = event.forceRefresh && _showTotal
          ? apiService.getCheckingAccountSum(
              type: 'pko',
              query: _search,
              dateFrom: dateFilter.sumFrom,
              dateTo: dateFilter.sumTo,
              approved: approved,
              deleted: deleted,
              leadId: leadId,
              cashRegisterId: cashRegisterId,
              supplierId: supplierId,
              authorId: authorId,
            )
          : null;

      final response = await listFuture;
      if (sumFuture != null) {
        try {
          _totalSum = await sumFuture;
        } catch (_) {
          _totalSum ??= 0;
        }
      }

      final newData = response.result?.data ?? [];

      if (event.forceRefresh) {
        _allData = List.from(newData);
      } else {
        _allData.addAll(newData);
      }

      final hasReachedMax = (response.result?.pagination?.currentPage ?? 1) >=
          (response.result?.pagination?.totalPages ?? 1);

      if (!hasReachedMax && newData.isNotEmpty) {
        _currentPage++;
      }

      final selectedDocuments =
          _allData.where((doc) => _selectedDocuments.contains(doc)).toList();

      emit(_buildLoadedState(
        data: List.from(_allData),
        pagination: response.result?.pagination,
        hasReachedMax: hasReachedMax,
        selectedData: selectedDocuments,
      ));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeError(friendlyError(e), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeError(friendlyError(e)));
      }
    }
  }

  Future<void> _onCreateMoneyIncome(
      CreateMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
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
        exchangeRate: event.exchangeRate,
      );

      emit(const MoneyIncomeCreateSuccess('document_created_successfully'));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeCreateError(friendlyError(e), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeCreateError(friendlyError(e)));
      }
    }
  }

  Future<void> _onUpdateMoneyIncome(
      UpdateMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeLoading());
    // use the same on UpdateThenToggleOneMoneyIncomeDocument
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
        exchangeRate: event.exchangeRate,
      );
      emit(const MoneyIncomeUpdateSuccess('document_updated_successfully'));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeUpdateError(friendlyError(e), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeUpdateError(friendlyError(e)));
      }
    }
  }

  Future<void> _onUpdateThenToggleOneMoneyIncomeDocument(
      UpdateThenToggleOneMoneyIncomeDocument event,
      Emitter<MoneyIncomeState> emit) async {
    // send two requests, first update, then toggle approve
    bool firstFailed = false;

    // use the same on UpdateMoneyIncome
    // first update
    try {
      await apiService.updateMoneyIncomeDocument(
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
        exchangeRate: event.exchangeRate,
      );
    } catch (e) {
      firstFailed = true;
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeUpdateError(friendlyError(e), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeUpdateError(friendlyError(e)));
      }
    }

    // send only if first succeeded
    if (firstFailed) {
      emit(_buildLoadedState(data: _allData));
      return;
    }

    await Future.delayed(const Duration(milliseconds: 2000));

    // then toggle approve
    try {
      await apiService.toggleApproveOneMoneyIncomeDocument(
          event.id, event.approve);
      // emit(const MoneyIncomeUpdateSuccess('document_updated_successfully'));
      // emit(MoneyIncomeToggleOneApproveSuccess("toggle_approve_success_message"));
      emit(MoneyIncomeUpdateThenToggleOneApproveSuccess(
          "document_updated_and_approve_toggled_successfully"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeToggleOneApproveError(friendlyError(e),
            statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeToggleOneApproveError(friendlyError(e)));
      }
    }
  }

  // only by swiping
  Future<void> _onDeleteMoneyIncome(
      DeleteMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    bool failed = false;

    // if (event.reload) emit(MoneyIncomeLoading());
    try {
      final result =
          await apiService.deleteMoneyIncomeDocument(event.document.id!);
      if (result) {
        // if (event.reload) emit(MoneyIncomeDeleteSuccess('document_deleted_successfully', reload: event.reload));
        // if (event.reload) add(RemoveLocalFromList(event.document.id!));
      } /* else {
        emit(const MoneyIncomeDeleteError('failed_to_delete_document'));
        failed = true;
      }*/
      emit(MoneyIncomeDeleteSuccess('document_deleted_successfully',
          reload: true));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeDeleteError(friendlyError(e), statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeDeleteError(friendlyError(e)));
      }
      failed = true;
    }

    if (failed) {
      add(FetchMoneyIncome(forceRefresh: true));
    } else {
      emit(_buildLoadedState(data: _allData));
    }
  }

  Future<void> _onRestoreMoneyIncome(
      RestoreMoneyIncome event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeLoading());

    try {
      await apiService.masRestoreMoneyIncomeDocuments([event.documentId]);
      emit(MoneyIncomeRestoreMassSuccess("mass_restore_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MoneyIncomeRestoreMassError(friendlyError(e),
            statusCode: e.statusCode));
      } else {
        emit(MoneyIncomeRestoreMassError(friendlyError(e)));
      }
      add(FetchMoneyIncome(forceRefresh: true));
    }
  }

  /// LOCAL LIST MANAGEMENT WITHOUT API CALLS

  Future<void> _onRemoveLocalFromList(
      RemoveLocalFromList event, Emitter<MoneyIncomeState> emit) async {
    emit(MoneyIncomeLoading());
    final double remainingPercentage = _allData.length / _perPage;

    if (remainingPercentage < 0.3) {
      add(FetchMoneyIncome(forceRefresh: true));
    } else {
      _allData.removeWhere((doc) => doc.id == event.documentId);
      emit(_buildLoadedState(
        data: List.from(_allData),
        pagination: null,
        hasReachedMax: false,
      ));
    }
  }

  Future<void> _onSelectDocument(
      SelectDocument event, Emitter<MoneyIncomeState> emit) async {
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

      emit(_buildLoadedState(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: selectedDocuments,
      ));
    }
  }

  Future<void> _onUnselectAllDocuments(
      UnselectAllDocuments event, Emitter<MoneyIncomeState> emit) async {
    _selectedDocuments = {};

    if (state is MoneyIncomeLoaded) {
      final currentState = state as MoneyIncomeLoaded;
      emit(_buildLoadedState(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: [],
      ));
    }
  }

  int? _intFilter(String key) {
    final value = _filters?[key];
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  MoneyIncomeLoaded _buildLoadedState({
    required List<Document> data,
    Pagination? pagination,
    bool? hasReachedMax,
    List<Document>? selectedData,
  }) {
    final current = state is MoneyIncomeLoaded ? state as MoneyIncomeLoaded : null;
    return MoneyIncomeLoaded(
      data: data,
      pagination: pagination ?? current?.pagination,
      hasReachedMax: hasReachedMax ?? current?.hasReachedMax ?? false,
      selectedData: selectedData ?? current?.selectedData ?? _selectedDocuments.toList(),
      totalSum: _totalSum,
      datePeriod: _datePeriod,
      showTotal: _showTotal,
    );
  }
}
