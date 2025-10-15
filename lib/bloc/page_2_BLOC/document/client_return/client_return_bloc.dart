import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/api_exception_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

part 'client_return_event.dart';
part 'client_return_state.dart';

class ClientReturnBloc extends Bloc<ClientReturnEvent, ClientReturnState> {
  final ApiService apiService;
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic> _filters = {};
  List<IncomingDocument> _allData = [];
  List<IncomingDocument> _selectedDocuments = [];

  ClientReturnBloc(this.apiService) : super(ClientReturnInitial()) {
    on<FetchClientReturns>(_onFetchData);
    on<CreateClientReturnDocument>(_onCreateClientReturnDocument);
    on<DeleteClientReturnDocument>(_delete);
    on<UpdateClientReturnDocument>(_onUpdateClientReturnDocument);
    on<RestoreClientReturnDocument>(_onRestoreClientReturnDocument);

    on<MassApproveClientReturnDocuments>(_onMassApproveClientReturnDocuments);
    on<MassDisapproveClientReturnDocuments>(_onMassDisapproveClientReturnDocuments);
    on<MassDeleteClientReturnDocuments>(_onMassDeleteClientReturnDocuments);
    on<MassRestoreClientReturnDocuments>(_onMassRestoreClientReturnDocuments);

    on<SelectClientReturnDocument>(_onSelectDocument);
    on<UnselectAllClientReturnDocuments>(_onUnselectAllDocuments);
  }

  _onFetchData(FetchClientReturns event, Emitter<ClientReturnState> emit) async {
    if (event.forceRefresh) {
      _currentPage = 1;
      _allData = [];
      _filters = event.filters ?? {};
      emit(ClientReturnLoading());
    } else if (state is ClientReturnLoaded &&
        (state as ClientReturnLoaded).hasReachedMax) {
      return; // Не делаем запрос, если достигнут конец
    }

    try {
      final response = await apiService.getClientReturns(
        page: _currentPage,
        perPage: _perPage,
        query: _filters['query'],
        dateFrom: _filters['date_from'],
        dateTo: _filters['date_to'],
        approved: _filters['approved'] != null ? int.tryParse(_filters['approved'].toString()) : null,
        deleted: _filters['deleted'] != null ? int.tryParse(_filters['deleted'].toString()) : null,
        leadId: _filters['lead_id'] != null ? int.tryParse(_filters['lead_id'].toString()) : null,
        cashRegisterId: _filters['cash_register_id'] != null ? int.tryParse(_filters['cash_register_id'].toString()) : null,
        supplierId: _filters['supplier_id'] != null ? int.tryParse(_filters['supplier_id'].toString()) : null,
        authorId: _filters['author_id'] != null ? int.tryParse(_filters['author_id'].toString()) : null,
        storageId: _filters['storage_id'] != null ? int.tryParse(_filters['storage_id'].toString()) : null,
      );

      final newData = response.data ?? [];
      _allData = event.forceRefresh ? newData : [..._allData, ...newData];
      final hasReachedMax = (response.pagination?.currentPage ?? 1) >=
          (response.pagination?.totalPages ?? 1);

      if (!hasReachedMax && newData.isNotEmpty) {
        _currentPage++;
      }

      final selectedDocuments = _allData.where((doc) => _selectedDocuments.contains(doc)).toList();

      emit(ClientReturnLoaded(
        data: _allData,
        pagination: response.pagination,
        hasReachedMax: hasReachedMax,
        selectedData: selectedDocuments,
      ));
    } catch (e) {
      if (e is ApiException) {
        emit(ClientReturnError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientReturnError(e.toString()));
      }
    }
  }

  _onCreateClientReturnDocument(
      CreateClientReturnDocument event, Emitter<ClientReturnState> emit) async {
    emit(ClientReturnCreateLoading());
    try {
      await apiService.createClientReturnDocument(
        date: event.date,
        storageId: event.storageId,
        comment: event.comment,
        counterpartyId: event.counterpartyId,
        documentGoods: event.documentGoods,
        organizationId: event.organizationId,
        salesFunnelId: event.salesFunnelId,
        approve: event.approve, // Передаем новый параметр
      );
      emit(ClientReturnCreateSuccess('Документ успешно создан'));
    } catch (e) {
      if (e is ApiException) {
        emit(ClientReturnCreateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientReturnCreateError(e.toString()));
      }
    }
  }

_delete(DeleteClientReturnDocument event, Emitter<ClientReturnState> emit) async {
  final isLastElement = _allData.length == 1;
  
  if (event.shouldReload || isLastElement) {
    emit(ClientReturnDeleteLoading());
  }

  try {
    final result = await apiService.deleteClientReturnDocument(event.documentId);
    
    if (result['result'] == 'Success') {
      _allData.removeWhere((doc) => doc.id == event.documentId);
      
      await Future.delayed(const Duration(milliseconds: 100));
      emit(ClientReturnDeleteSuccess(
        'Документ успешно удален',
        shouldReload: event.shouldReload || isLastElement
      ));
    } else {
      emit(const ClientReturnDeleteError('Не удалось удалить документ'));
    }
  } catch (e) {
    if (e is ApiException) {
      emit(ClientReturnDeleteError(
        'Ошибка при удалении документа: ${e.toString()}',
        statusCode: e.statusCode
      ));
    } else {
      emit(ClientReturnDeleteError('Ошибка при удалении документа: ${e.toString()}'));
    }
  }
  
  if (_allData.isNotEmpty) {
    final selectedDocuments = _allData.where((doc) => _selectedDocuments.contains(doc)).toList();
    emit(ClientReturnLoaded(
      data: List.from(_allData),
      hasReachedMax: state is ClientReturnLoaded ? (state as ClientReturnLoaded).hasReachedMax : false,
      selectedData: selectedDocuments,
    ));
  }
}

  // Массовые операции
  Future<void> _onMassApproveClientReturnDocuments(
      MassApproveClientReturnDocuments event, Emitter<ClientReturnState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == 0 && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllClientReturnDocuments());

    try {
      await apiService.massApproveClientReturnDocuments(ls);
      emit(const ClientReturnApproveMassSuccess("mass_approve_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(ClientReturnApproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientReturnApproveMassError(e.toString()));
      }
      add(FetchClientReturns(forceRefresh: true));
    }

    emit(ClientReturnLoaded(data: _allData));
  }

  Future<void> _onMassDisapproveClientReturnDocuments(
      MassDisapproveClientReturnDocuments event, Emitter<ClientReturnState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == 1 && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllClientReturnDocuments());

    try {
      await apiService.massDisapproveClientReturnDocuments(ls);
      emit(const ClientReturnDisapproveMassSuccess("mass_disapprove_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(ClientReturnDisapproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientReturnDisapproveMassError(e.toString()));
      }
      add(FetchClientReturns(forceRefresh: true));
    }

    emit(ClientReturnLoaded(data: _allData));
  }

  Future<void> _onMassDeleteClientReturnDocuments(
      MassDeleteClientReturnDocuments event, Emitter<ClientReturnState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllClientReturnDocuments());

    try {
      await apiService.massDeleteClientReturnDocuments(ls);
      
      _allData.removeWhere((doc) => ls.contains(doc.id));
      
      emit(const ClientReturnDeleteMassSuccess("mass_delete_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(ClientReturnDeleteMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientReturnDeleteMassError(e.toString()));
      }
      add(FetchClientReturns(forceRefresh: true));
    }

    emit(ClientReturnLoaded(data: List.from(_allData), selectedData: List.from(_selectedDocuments)));
  }

  Future<void> _onMassRestoreClientReturnDocuments(
      MassRestoreClientReturnDocuments event, Emitter<ClientReturnState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt != null).map((e) => e.id!).toList();
    add(UnselectAllClientReturnDocuments());

    try {
      await apiService.massRestoreClientReturnDocuments(ls);
      emit(const ClientReturnRestoreMassSuccess("mass_restore_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(ClientReturnRestoreMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientReturnRestoreMassError(e.toString()));
      }
      add(FetchClientReturns(forceRefresh: true));
    }

    emit(ClientReturnLoaded(data: _allData));
  }

  // Выбор документов
  Future<void> _onSelectDocument(
      SelectClientReturnDocument event, Emitter<ClientReturnState> emit) async {
    if (state is ClientReturnLoaded) {
      final currentState = state as ClientReturnLoaded;

      if (_selectedDocuments.contains(event.document)) {
        _selectedDocuments.remove(event.document);
      } else {
        _selectedDocuments.add(event.document);
      }

      final selectedDocuments = currentState.data.where((doc) => _selectedDocuments.contains(doc)).toList();

      emit(ClientReturnLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: selectedDocuments,
      ));
    }
  }

  Future<void> _onUnselectAllDocuments(
      UnselectAllClientReturnDocuments event, Emitter<ClientReturnState> emit) async {
    _selectedDocuments = [];

    if (state is ClientReturnLoaded) {
      final currentState = state as ClientReturnLoaded;
      emit(ClientReturnLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: [],
      ));
    }
  }

  _onRestoreClientReturnDocument(
      RestoreClientReturnDocument event, Emitter<ClientReturnState> emit) async {
    emit(ClientReturnRestoreLoading());
    
    try {
      final result = await apiService.restoreClientReturnDocument(event.documentId);
      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(const ClientReturnRestoreSuccess('Документ успешно восстановлен'));
      } else {
        emit(const ClientReturnRestoreError('Не удалось восстановить документ'));
      }
    } catch (e) {
      if (e is ApiException) {
        emit(ClientReturnRestoreError(
          'Ошибка при восстановлении документа: ${e.toString()}',
          statusCode: e.statusCode
        ));
      } else {
        emit(ClientReturnRestoreError('Ошибка при восстановлении документа: ${e.toString()}'));
      }
    }
  }

  _onUpdateClientReturnDocument(
      UpdateClientReturnDocument event, Emitter<ClientReturnState> emit) async {
    emit(ClientReturnCreateLoading());
    try {
      await apiService.updateClientReturnDocument(
        documentId: event.documentId,
        date: event.date,
        storageId: event.storageId,
        comment: event.comment,
        counterpartyId: event.counterpartyId,
        documentGoods: event.documentGoods,
        organizationId: event.organizationId,
        salesFunnelId: event.salesFunnelId,
      );
      emit(ClientReturnUpdateSuccess('Документ успешно обновлен'));
    } catch (e) {
      if (e is ApiException) {
        emit(ClientReturnUpdateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientReturnUpdateError(e.toString()));
      }
    }
  }
}