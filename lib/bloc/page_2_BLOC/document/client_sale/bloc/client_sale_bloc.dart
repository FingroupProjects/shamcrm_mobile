import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../models/api_exception_model.dart';

part 'client_sale_event.dart';
part 'client_sale_state.dart';

class ClientSaleBloc extends Bloc<ClientSaleEvent, ClientSaleState> {
  final ApiService apiService;
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic> _filters = {};
  List<IncomingDocument> _allData = [];

  ClientSaleBloc(this.apiService) : super(ClientSaleInitial()) {
    on<FetchClientSales>(_onFetchData);
    on<CreateClientSalesDocument>(_onCreateClientSalesDocument);
    on<DeleteClientSalesDocument>(_delete);
    on<UpdateClientSalesDocument>(_onUpdateClientSalesDocument);
  }

  _onFetchData(FetchClientSales event, Emitter<ClientSaleState> emit) async {
    if (event.forceRefresh) {
      _currentPage = 1;
      _allData = [];
      _filters = event.filters ?? {};
      emit(ClientSaleLoading());
    } else if (state is ClientSaleLoading &&
        (state as ClientSaleLoaded).hasReachedMax) {
      return; // Не делаем запрос, если достигнут конец
    }

    try {
      final response = await apiService.getClientSales(
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

      emit(ClientSaleLoaded(
        data: _allData,
        pagination: response.pagination,
        hasReachedMax: hasReachedMax,
      ));
    } catch (e) {
      if (e is ApiException) {
        emit(ClientSaleError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientSaleError(e.toString()));
      }
    }
  }

  _onCreateClientSalesDocument(CreateClientSalesDocument event, Emitter<ClientSaleState> emit) async {
    emit(ClientSaleCreateLoading());
    try {
      final response = await apiService.createClientSaleDocument(
        date: event.date,
        storageId: event.storageId,
        comment: event.comment,
        counterpartyId: event.counterpartyId,
        documentGoods: event.documentGoods,
        organizationId: event.organizationId,
        salesFunnelId: event.salesFunnelId,
        approve: event.approve, // Передаем новый параметр
      );

      emit(ClientSaleCreateSuccess('Документ успешно создан'));
    } catch (e) {
      if (e is ApiException) {
        emit(ClientSaleCreateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientSaleCreateError(e.toString()));
      }
    }
  }

  _delete(
      DeleteClientSalesDocument event, Emitter<ClientSaleState> emit) async {
    try {
      await apiService.deleteClientSaleDocument(event.documentId);
      // emit(ClientSaleDeleteSuccess('Документ успешно удален'));
      add(FetchClientSales(forceRefresh: true, filters: _filters));
    } catch (e) {
      if (e is ApiException) {
        emit(ClientSaleError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientSaleError(e.toString()));
      }
    }
  }

  _onUpdateClientSalesDocument(
  UpdateClientSalesDocument event, Emitter<ClientSaleState> emit) async {
  emit(ClientSaleCreateLoading());
  try {
    await apiService.updateClientSaleDocument(
      documentId: event.documentId,
      date: event.date,
      storageId: event.storageId,
      comment: event.comment,
      counterpartyId: event.counterpartyId,
      documentGoods: event.documentGoods,
      organizationId: event.organizationId,
      salesFunnelId: event.salesFunnelId,
    );
    emit(ClientSaleUpdateSuccess('Документ успешно обновлен'));
  } catch (e) {
    if (e is ApiException) {
      emit(ClientSaleUpdateError(e.toString(), statusCode: e.statusCode));
    } else {
      emit(ClientSaleUpdateError(e.toString()));
    }
  }
}
}
