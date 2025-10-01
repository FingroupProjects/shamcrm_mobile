import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/api_exception_model.dart';

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
        fromDate: _filters['fromDate'],
        toDate: _filters['toDate'],
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
    await apiService.deleteClientReturnDocument(event.documentId);
    
    _allData.removeWhere((doc) => doc.id == event.documentId);
    
    await Future.delayed(const Duration(milliseconds: 100));
    emit(ClientReturnDeleteSuccess(
      'Документ успешно удален',
      shouldReload: event.shouldReload || isLastElement
    ));
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