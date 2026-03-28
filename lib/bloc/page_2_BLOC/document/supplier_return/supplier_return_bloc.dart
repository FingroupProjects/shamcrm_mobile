import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import '../../../../models/api_exception_model.dart';
import 'supplier_return_event.dart';
import 'supplier_return_state.dart';

class SupplierReturnBloc extends Bloc<SupplierReturnEvent, SupplierReturnState> {
  final ApiService apiService;
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic> _filters = {};
  List<IncomingDocument> _allData = [];
  List<IncomingDocument> _selectedDocuments = [];

  SupplierReturnBloc(this.apiService) : super(SupplierReturnInitial()) {
    on<FetchSupplierReturn>(_onFetchSupplierReturn);
    on<CreateSupplierReturn>(_onCreateSupplierReturn);
    on<UpdateSupplierReturn>(_onUpdateSupplierReturn);
    on<DeleteSupplierReturn>(_onDeleteSupplierReturn);
    on<RestoreSupplierReturn>(_onRestoreSupplierReturn);

    on<MassApproveSupplierReturnDocuments>(_onMassApproveSupplierReturnDocuments);
    on<MassDisapproveSupplierReturnDocuments>(_onMassDisapproveSupplierReturnDocuments);
    on<MassDeleteSupplierReturnDocuments>(_onMassDeleteSupplierReturnDocuments);
    on<MassRestoreSupplierReturnDocuments>(_onMassRestoreSupplierReturnDocuments);

    on<SelectSupplierReturnDocument>(_onSelectDocument);
    on<UnselectAllSupplierReturnDocuments>(_onUnselectAllDocuments);
  }

  Future<void> _onRestoreSupplierReturn(RestoreSupplierReturn event, Emitter<SupplierReturnState> emit) async {
    emit(SupplierReturnRestoreLoading());
    try {
      final result = await apiService.restoreSupplierReturnDocument(event.documentId);
      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(SupplierReturnRestoreSuccess('Документ успешно восстановлен'));
      } else {
        emit(SupplierReturnRestoreError('Не удалось восстановить документ'));
      }
    } catch (e) {
      if (e is ApiException) {
        emit(SupplierReturnRestoreError('Ошибка при восстановлении документа: ${e.toString()}', statusCode: e.statusCode));
      } else {
        emit(SupplierReturnRestoreError('Ошибка при восстановлении документа: ${e.toString()}'));
      }
    }
  }

  Future<void> _onFetchSupplierReturn(FetchSupplierReturn event, Emitter<SupplierReturnState> emit) async {
    if (event.forceRefresh) {
      _currentPage = 1;
      _allData = [];
      _filters = event.filters ?? {};
      emit(SupplierReturnLoading());
    } else if (state is SupplierReturnLoaded && (state as SupplierReturnLoaded).hasReachedMax) {
      return;
    }

    try {
      final response = await apiService.getSupplierReturnDocuments(
        page: _currentPage,
        perPage: _perPage,
        query: _filters['query'],
        fromDate: _filters['fromDate'],
        toDate: _filters['toDate'],
      );

      final newData = response.data ?? [];
      _allData = event.forceRefresh ? newData : [..._allData, ...newData];

      final hasReachedMax = (response.pagination?.currentPage ?? 1) >= (response.pagination?.totalPages ?? 1);

      if (!hasReachedMax && newData.isNotEmpty) {
        _currentPage++;
      }

      final selectedDocuments = _allData.where((doc) => _selectedDocuments.contains(doc)).toList();

      emit(SupplierReturnLoaded(
        data: _allData,
        pagination: response.pagination,
        hasReachedMax: hasReachedMax,
        selectedData: selectedDocuments,
      ));
    } catch (e) {
      if (e is ApiException) {
        emit(SupplierReturnError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(SupplierReturnError(e.toString()));
      }
    }
  }

  Future<void> _onCreateSupplierReturn(CreateSupplierReturn event, Emitter<SupplierReturnState> emit) async {
    emit(SupplierReturnCreateLoading());
    try {
      await apiService.createSupplierReturnDocument(
        date: event.date,
        storageId: event.storageId,
        comment: event.comment,
        counterpartyId: event.counterpartyId,
        documentGoods: event.documentGoods,
        organizationId: event.organizationId,
        salesFunnelId: event.salesFunnelId,
        approve: event.approve, // Передаем новый параметр
      );

      await Future.delayed(const Duration(milliseconds: 100));
      emit(SupplierReturnCreateSuccess('Документ успешно создан'));
    } catch (e) {
      if (e is ApiException) {
        emit(SupplierReturnCreateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(SupplierReturnCreateError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateSupplierReturn(UpdateSupplierReturn event, Emitter<SupplierReturnState> emit) async {
    emit(SupplierReturnUpdateLoading());
    try {
      await apiService.updateSupplierReturnDocument(
        documentId: event.documentId,
        date: event.date,
        storageId: event.storageId,
        comment: event.comment,
        counterpartyId: event.counterpartyId,
        documentGoods: event.documentGoods,
        organizationId: event.organizationId,
        salesFunnelId: event.salesFunnelId,
      );

      await Future.delayed(const Duration(milliseconds: 100));
      emit(SupplierReturnUpdateSuccess('Документ успешно обновлен'));
    } catch (e) {
      if (e is ApiException) {
        emit(SupplierReturnUpdateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(SupplierReturnUpdateError(e.toString()));
      }
    }
  }

 Future<void> _onDeleteSupplierReturn(DeleteSupplierReturn event, Emitter<SupplierReturnState> emit) async {
  final isLastElement = _allData.length == 1;
  
  if (event.shouldReload || isLastElement) {
    emit(SupplierReturnDeleteLoading());
  }

  try {
    final result = await apiService.deleteSupplierReturnDocument(event.documentId);
    
    if (result['result'] == 'Success') {
      _allData.removeWhere((doc) => doc.id == event.documentId);
      
      await Future.delayed(const Duration(milliseconds: 100));
      emit(SupplierReturnDeleteSuccess(
        'Документ успешно удален',
        shouldReload: event.shouldReload || isLastElement
      ));
    } else {
      emit(SupplierReturnDeleteError('Не удалось удалить документ'));
    }
  } catch (e) {
    if (e is ApiException) {
      emit(SupplierReturnDeleteError(
        'Ошибка при удалении документа: ${e.toString()}',
        statusCode: e.statusCode
      ));
    } else {
      emit(SupplierReturnDeleteError('Ошибка при удалении документа: ${e.toString()}'));
    }
  }
  
  if (_allData.isNotEmpty) {
    final selectedDocuments = _allData.where((doc) => _selectedDocuments.contains(doc)).toList();
    emit(SupplierReturnLoaded(
      data: List.from(_allData),
      hasReachedMax: state is SupplierReturnLoaded ? (state as SupplierReturnLoaded).hasReachedMax : false,
      selectedData: selectedDocuments,
    ));
  }
}

  // Массовые операции (используем последовательные вызовы single-методов)
  Future<void> _onMassApproveSupplierReturnDocuments(
      MassApproveSupplierReturnDocuments event, Emitter<SupplierReturnState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == 0 && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllSupplierReturnDocuments());

    if (ls.isEmpty) {
      emit(const SupplierReturnApproveMassSuccess("Нет документов для одобрения"));
      return;
    }

    try {
      // Последовательное одобрение каждого документа
      for (final id in ls) {
        await apiService.approveSupplierReturnDocument(id);
      }
      emit(const SupplierReturnApproveMassSuccess("mass_approve_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(SupplierReturnApproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(SupplierReturnApproveMassError(e.toString()));
      }
      add(FetchSupplierReturn(forceRefresh: true));
    }

    emit(SupplierReturnLoaded(data: _allData));
  }

  Future<void> _onMassDisapproveSupplierReturnDocuments(
      MassDisapproveSupplierReturnDocuments event, Emitter<SupplierReturnState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == 1 && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllSupplierReturnDocuments());

    if (ls.isEmpty) {
      emit(const SupplierReturnDisapproveMassSuccess("Нет документов для отмены одобрения"));
      return;
    }

    try {
      // Последовательная отмена одобрения каждого документа
      for (final id in ls) {
        await apiService.unApproveSupplierReturnDocument(id);
      }
      emit(const SupplierReturnDisapproveMassSuccess("mass_disapprove_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(SupplierReturnDisapproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(SupplierReturnDisapproveMassError(e.toString()));
      }
      add(FetchSupplierReturn(forceRefresh: true));
    }

    emit(SupplierReturnLoaded(data: _allData));
  }

  Future<void> _onMassDeleteSupplierReturnDocuments(
      MassDeleteSupplierReturnDocuments event, Emitter<SupplierReturnState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllSupplierReturnDocuments());

    if (ls.isEmpty) {
      emit(const SupplierReturnDeleteMassSuccess("Нет документов для удаления"));
      return;
    }

    try {
      // Последовательное удаление каждого документа
      for (final id in ls) {
        await apiService.deleteSupplierReturnDocument(id);
      }
      
      _allData.removeWhere((doc) => ls.contains(doc.id));
      
      emit(const SupplierReturnDeleteMassSuccess("mass_delete_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(SupplierReturnDeleteMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(SupplierReturnDeleteMassError(e.toString()));
      }
      add(FetchSupplierReturn(forceRefresh: true));
    }

    emit(SupplierReturnLoaded(data: List.from(_allData), selectedData: List.from(_selectedDocuments)));
  }

  Future<void> _onMassRestoreSupplierReturnDocuments(
      MassRestoreSupplierReturnDocuments event, Emitter<SupplierReturnState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt != null).map((e) => e.id!).toList();
    add(UnselectAllSupplierReturnDocuments());

    if (ls.isEmpty) {
      emit(const SupplierReturnRestoreMassSuccess("Нет документов для восстановления"));
      return;
    }

    try {
      // Последовательное восстановление каждого документа
      for (final id in ls) {
        await apiService.restoreSupplierReturnDocument(id);
      }
      emit(const SupplierReturnRestoreMassSuccess("mass_restore_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(SupplierReturnRestoreMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(SupplierReturnRestoreMassError(e.toString()));
      }
      add(FetchSupplierReturn(forceRefresh: true));
    }

    emit(SupplierReturnLoaded(data: _allData));
  }

  // Выбор документов
  Future<void> _onSelectDocument(
      SelectSupplierReturnDocument event, Emitter<SupplierReturnState> emit) async {
    if (state is SupplierReturnLoaded) {
      final currentState = state as SupplierReturnLoaded;

      if (_selectedDocuments.contains(event.document)) {
        _selectedDocuments.remove(event.document);
      } else {
        _selectedDocuments.add(event.document);
      }

      final selectedDocuments = currentState.data.where((doc) => _selectedDocuments.contains(doc)).toList();

      emit(SupplierReturnLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: selectedDocuments,
      ));
    }
  }

  Future<void> _onUnselectAllDocuments(
      UnselectAllSupplierReturnDocuments event, Emitter<SupplierReturnState> emit) async {
    _selectedDocuments = [];

    if (state is SupplierReturnLoaded) {
      final currentState = state as SupplierReturnLoaded;
      emit(SupplierReturnLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: [],
      ));
    }
  }
}