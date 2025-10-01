import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/api_exception_model.dart';

part 'client_return_event.dart';
part 'client_return_state.dart';

class ClientReturnBloc extends Bloc<ClientReturnEvent, ClientReturnState> {
  final ApiService apiService;
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic>? _filters;
  String? _search = '';
  List<IncomingDocument> _allData = [];
  List<IncomingDocument> _selectedDocuments = [];

  ClientReturnBloc(this.apiService) : super(ClientReturnInitial()) {
    on<FetchClientReturns>(_onFetchData);
    on<CreateClientReturnDocument>(_onCreateClientReturnDocument);
    on<DeleteClientReturn>(_delete);
    on<UpdateClientReturnDocument>(_onUpdateClientReturnDocument);
    on<RestoreClientReturn>(_onRestoreClientReturn);

    on<MassApproveClientReturnDocuments>(_onMassApproveClientReturnDocuments);
    on<MassDisapproveClientReturnDocuments>(_onMassDisapproveClientReturnDocuments);
    on<MassDeleteClientReturnDocuments>(_onMassDeleteClientReturnDocuments);
    on<MassRestoreClientReturnDocuments>(_onMassRestoreClientReturnDocuments);

    on<SelectDocument>(_onSelectDocument);
    on<UnselectAllDocuments>(_onUnselectAllDocuments);
  }

  Future<void> _onMassApproveClientReturnDocuments(MassApproveClientReturnDocuments event, Emitter<ClientReturnState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == 0 && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massApproveClientReturnDocuments(ls);
      emit(ClientReturnApproveMassSuccess("Документы успешно проведены"));
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

  Future<void> _onMassDisapproveClientReturnDocuments(MassDisapproveClientReturnDocuments event, Emitter<ClientReturnState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == 1 && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massDisapproveClientReturnDocuments(ls);
      emit(ClientReturnDisapproveMassSuccess("Документы успешно отменены"));
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

  Future<void> _onMassDeleteClientReturnDocuments(MassDeleteClientReturnDocuments event, Emitter<ClientReturnState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massDeleteClientReturnDocuments(ls);
      emit(ClientReturnDeleteMassSuccess("Документы успешно удалены"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(ClientReturnDeleteMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientReturnDeleteMassError(e.toString()));
      }
      add(FetchClientReturns(forceRefresh: true));
    }

    emit(ClientReturnLoaded(data: _allData));
  }

  Future<void> _onMassRestoreClientReturnDocuments(MassRestoreClientReturnDocuments event, Emitter<ClientReturnState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt != null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massRestoreClientReturnDocuments(ls);
      emit(ClientReturnRestoreMassSuccess("Документы успешно восстановлены"));
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

  Future<void> _onSelectDocument(SelectDocument event, Emitter<ClientReturnState> emit) async {
    if (state is ClientReturnLoaded) {
      final currentState = state as ClientReturnLoaded;

      if (_selectedDocuments.contains(event.document)) {
        _selectedDocuments.remove(event.document);
      } else {
        _selectedDocuments.add(event.document);
      }

      final selectedDocuments = currentState.data
          .where((doc) => _selectedDocuments.contains(doc))
          .toList();

      emit(ClientReturnLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: selectedDocuments,
      ));
    }
  }

  Future<void> _onUnselectAllDocuments(UnselectAllDocuments event, Emitter<ClientReturnState> emit) async {
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

  Future<void> _onRestoreClientReturn(RestoreClientReturn event, Emitter<ClientReturnState> emit) async {
    emit(ClientReturnRestoreLoading());
    try {
      final result = await apiService.restoreClientReturnDocument(event.documentId);
      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(ClientReturnRestoreSuccess('Документ успешно восстановлен'));
      } else {
        emit(ClientReturnRestoreError('Не удалось восстановить документ'));
      }
    } catch (e) {
      if (e is ApiException) {
        emit(ClientReturnRestoreError('Ошибка при восстановлении документа: ${e.toString()}', statusCode: e.statusCode));
      } else {
        emit(ClientReturnRestoreError('Ошибка при восстановлении документа: ${e.toString()}'));
      }
    }
  }

  _onFetchData(FetchClientReturns event, Emitter<ClientReturnState> emit) async {
    print("_onFetchData. ClientReturnBloc");
    if (event.forceRefresh || _allData.isEmpty) {
      emit(ClientReturnLoading());
    }

    if (event.forceRefresh) {
      _currentPage = 1;
      _allData.clear();
      _filters = event.filters;
      _search = event.search;
    } else if (state is ClientReturnLoaded && (state as ClientReturnLoaded).hasReachedMax) {
      return;
    }

    try {
      final response = await apiService.getClientReturns(
        page: _currentPage,
        perPage: _perPage,
        query: _search,
        fromDate: _filters?['fromDate'],
        toDate: _filters?['toDate'],
      );

      final newData = response.data ?? [];

      if (event.forceRefresh) {
        _allData.clear();
        _allData = List.from(newData);
      } else {
        _allData.addAll(newData);
      }

      debugPrint("_onFetchData. ClientReturnBloc: ${_allData}");

      final hasReachedMax = (response.pagination?.currentPage ?? 1) >= (response.pagination?.totalPages ?? 1);

      if (!hasReachedMax && newData.isNotEmpty) {
        _currentPage++;
      }

      final selectedDocuments = _allData
          .where((doc) => _selectedDocuments.contains(doc))
          .toList();

      emit(ClientReturnLoaded(
        data: List.from(_allData),
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
      final response = await apiService.createClientReturnDocument(
        date: event.date,
        storageId: event.storageId,
        comment: event.comment,
        counterpartyId: event.counterpartyId,
        documentGoods: event.documentGoods,
        organizationId: event.organizationId,
        salesFunnelId: event.salesFunnelId,
        approve: event.approve,
      );
      await Future.delayed(const Duration(milliseconds: 100));
      emit(ClientReturnCreateSuccess(
          event.approve
              ? 'Документ успешно создан и проведен'
              : 'Документ успешно создан'
      ));
    } catch (e) {
      if (e is ApiException) {
        emit(ClientReturnCreateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientReturnCreateError(e.toString()));
      }
    }
  }

  _delete(DeleteClientReturn event, Emitter<ClientReturnState> emit) async {
    if(event.shouldReload) emit(ClientReturnDeleteLoading());
    try {
      final result = await apiService.deleteClientReturnDocument(event.documentId);
      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(ClientReturnDeleteSuccess('Документ успешно удален', shouldReload: event.shouldReload || _allData.isEmpty));
      } else {
        emit(ClientReturnDeleteError('Не удалось удалить документ'));
      }
    } catch (e) {
      if (e is ApiException) {
        emit(ClientReturnDeleteError('Ошибка при удалении документа: ${e.toString()}', statusCode: e.statusCode));
      } else {
        emit(ClientReturnDeleteError('Ошибка при удалении документа: ${e.toString()}'));
      }
    }
    emit(ClientReturnLoaded(data: _allData, selectedData: _selectedDocuments));
  }

  _onUpdateClientReturnDocument(
      UpdateClientReturnDocument event, Emitter<ClientReturnState> emit) async {
    emit(ClientReturnUpdateLoading());
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
      await Future.delayed(const Duration(milliseconds: 100));
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