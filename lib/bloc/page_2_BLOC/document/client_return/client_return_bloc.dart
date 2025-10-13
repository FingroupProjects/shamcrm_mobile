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

  ClientReturnBloc(this.apiService) : super(ClientReturnInitial()) {
    on<FetchClientReturns>(_onFetchData);
    on<CreateClientReturnDocument>(_onCreateClientReturnDocument);
    on<DeleteClientReturnDocument>(_delete);
    on<UpdateClientReturnDocument>(_onUpdateClientReturnDocument);
    on<RestoreClientReturnDocument>(_onRestoreClientReturnDocument);
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

      emit(ClientReturnLoaded(
        data: _allData,
        pagination: response.pagination,
        hasReachedMax: hasReachedMax,
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
    emit(ClientReturnLoaded(
      data: List.from(_allData),
      hasReachedMax: state is ClientReturnLoaded ? (state as ClientReturnLoaded).hasReachedMax : false,
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