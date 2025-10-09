import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../models/api_exception_model.dart';

part 'client_sale_event.dart';

part 'client_sale_state.dart';

class ClientSaleBloc extends Bloc<ClientSaleEvent, ClientSaleState> {
  final ApiService apiService;
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic>? _filters;
  String? _search = '';
  List<IncomingDocument> _allData = [];
  List<IncomingDocument> _selectedDocuments = [];

  ClientSaleBloc(this.apiService) : super(ClientSaleInitial()) {
    on<FetchClientSales>(_onFetchData);
    on<CreateClientSalesDocument>(_onCreateClientSalesDocument);
    on<DeleteClientSale>(_onDeleteClientSale);
    on<RestoreClientSale>(_onRestoreClientSale);
    on<UpdateClientSalesDocument>(_onUpdateClientSalesDocument);

    on<MassApproveClientSaleDocuments>(_onMassApproveClientSaleDocuments);
    on<MassDisapproveClientSaleDocuments>(_onMassDisapproveClientSaleDocuments);
    on<MassDeleteClientSaleDocuments>(_onMassDeleteClientSaleDocuments);
    on<MassRestoreClientSaleDocuments>(_onMassRestoreClientSaleDocuments);

    on<SelectDocument>(_onSelectDocument);
    on<UnselectAllDocuments>(_onUnselectAllDocuments);
  }

  Future<void> _onMassApproveClientSaleDocuments(MassApproveClientSaleDocuments event, Emitter<ClientSaleState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == 0 && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massApproveClientSaleDocuments(ls);
      emit(ClientSaleApproveMassSuccess("mass_approve_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(ClientSaleApproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientSaleApproveMassError(e.toString()));
      }
      add(FetchClientSales(forceRefresh: true));
    }

    emit(ClientSaleLoaded(data: _allData));
  }

  Future<void> _onMassDisapproveClientSaleDocuments(
      MassDisapproveClientSaleDocuments event, Emitter<ClientSaleState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == 1 && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massDisapproveClientSaleDocuments(ls);
      emit(ClientSaleDisapproveMassSuccess("mass_disapprove_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(ClientSaleDisapproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientSaleDisapproveMassError(e.toString()));
      }
      add(FetchClientSales(forceRefresh: true));
    }

    emit(ClientSaleLoaded(data: _allData));
  }
Future<void> _onMassDeleteClientSaleDocuments(MassDeleteClientSaleDocuments event, Emitter<ClientSaleState> emit) async {
  final ls = _selectedDocuments.where((e) => e.deletedAt == null).map((e) => e.id!).toList();
  add(UnselectAllDocuments());

  try {
    await apiService.massDeleteClientSaleDocuments(ls);
    
    _allData.removeWhere((doc) => ls.contains(doc.id));
    
    emit(ClientSaleDeleteMassSuccess("mass_delete_success_message"));
  } catch (e) {
    if (e is ApiException && e.statusCode == 409) {
      emit(ClientSaleDeleteMassError(e.toString(), statusCode: e.statusCode));
    } else {
      emit(ClientSaleDeleteMassError(e.toString()));
    }
    add(FetchClientSales(forceRefresh: true));
  }

  emit(ClientSaleLoaded(data: List.from(_allData), selectedData: List.from(_selectedDocuments)));
}
  Future<void> _onMassRestoreClientSaleDocuments(MassRestoreClientSaleDocuments event, Emitter<ClientSaleState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt != null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massRestoreClientSaleDocuments(ls);
      emit(ClientSaleRestoreMassSuccess("mass_restore_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(ClientSaleRestoreMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientSaleRestoreMassError(e.toString()));
      }
      add(FetchClientSales(forceRefresh: true));
    }

    emit(ClientSaleLoaded(data: _allData));
  }

  Future<void> _onSelectDocument(SelectDocument event, Emitter<ClientSaleState> emit) async {
    if (state is ClientSaleLoaded) {
      final currentState = state as ClientSaleLoaded;

      if (_selectedDocuments.contains(event.document)) {
        _selectedDocuments.remove(event.document);
      } else {
        _selectedDocuments.add(event.document);
      }

      final selectedDocuments = currentState.data.where((doc) => _selectedDocuments.contains(doc)).toList();

      emit(ClientSaleLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: selectedDocuments,
      ));
    }
  }

  Future<void> _onUnselectAllDocuments(UnselectAllDocuments event, Emitter<ClientSaleState> emit) async {
    _selectedDocuments = [];

    if (state is ClientSaleLoaded) {
      final currentState = state as ClientSaleLoaded;
      emit(ClientSaleLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: [],
      ));
    }
  }

  Future<void> _onRestoreClientSale(RestoreClientSale event, Emitter<ClientSaleState> emit) async {
    emit(ClientSaleRestoreLoading());
    try {
      final result = await apiService.restoreClientSaleDocument(event.documentId);
      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(ClientSaleRestoreSuccess('Документ успешно восстановлен'));
      } else {
        emit(ClientSaleRestoreError('Не удалось восстановить документ'));
      }
    } catch (e) {
      if (e is ApiException) {
        emit(ClientSaleRestoreError('Ошибка при восстановлении документа: ${e.toString()}', statusCode: e.statusCode));
      } else {
        emit(ClientSaleRestoreError('Ошибка при восстановлении документа: ${e.toString()}'));
      }
    }
  }

  _onFetchData(FetchClientSales event, Emitter<ClientSaleState> emit) async {
    if (event.forceRefresh || _allData.isEmpty) {
      emit(ClientSaleLoading());
    }

    if (event.forceRefresh) {
      _currentPage = 1;
      _allData.clear();
      _filters = event.filters;
      _search = event.search;
    } else if (state is ClientSaleLoaded && (state as ClientSaleLoaded).hasReachedMax) {
      return;
    }

    try {
      final response = await apiService.getClientSales(
        page: _currentPage,
        perPage: _perPage,
        query: _search,
        dateFrom: _filters?['date_from'],
        dateTo: _filters?['date_to'],
        approved: _filters?['approved'],
        deleted: _filters?['deleted'],
        leadId: _filters?['lead_id'],
        cashRegisterId: _filters?['cash_register_id'],
        supplierId: _filters?['supplier_id'],
        authorId: _filters?['author_id'],
      );

      final newData = response.data ?? [];

      if (event.forceRefresh) {
        _allData = List.from(newData);
      } else {
        _allData.addAll(newData);
      }

      final hasReachedMax = (response.pagination?.currentPage ?? 1) >= (response.pagination?.totalPages ?? 1);

      if (!hasReachedMax && newData.isNotEmpty) {
        _currentPage++;
      }

      final selectedDocuments = _allData.where((doc) => _selectedDocuments.contains(doc)).toList();

      emit(ClientSaleLoaded(
        data: List.from(_allData),
        pagination: response.pagination,
        hasReachedMax: hasReachedMax,
        selectedData: selectedDocuments,
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
        approve: event.approve,
      );

      await Future.delayed(const Duration(milliseconds: 100));
      emit(ClientSaleCreateSuccess(event.approve ? 'Документ успешно создан и проведен' : 'Документ успешно создан'));
    } catch (e) {
      if (e is ApiException) {
        emit(ClientSaleCreateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(ClientSaleCreateError(e.toString()));
      }
    }
  }

_onDeleteClientSale(DeleteClientSale event, Emitter<ClientSaleState> emit) async {
  final isLastElement = _allData.length == 1;
  
  if (event.shouldReload || isLastElement) {
    emit(ClientSaleDeleteLoading());
  }

  try {
    final result = await apiService.deleteClientSaleDocument(event.documentId);
    
    if (result['result'] == 'Success') {
      _allData.removeWhere((doc) => doc.id == event.documentId);
      _selectedDocuments.removeWhere((doc) => doc.id == event.documentId);
      
      await Future.delayed(const Duration(milliseconds: 100));
      emit(ClientSaleDeleteSuccess(
        'Документ успешно удален', 
        shouldReload: event.shouldReload || isLastElement
      ));
    } else {
      emit(ClientSaleDeleteError('Не удалось удалить документ'));
    }
  } catch (e) {
    if (e is ApiException) {
      emit(ClientSaleDeleteError(
        'Ошибка при удалении документа: ${e.toString()}', 
        statusCode: e.statusCode
      ));
    } else {
      emit(ClientSaleDeleteError('Ошибка при удалении документа: ${e.toString()}'));
    }
  }
  
  if (_allData.isNotEmpty) {
    emit(ClientSaleLoaded(
      data: List.from(_allData), 
      selectedData: List.from(_selectedDocuments),
      hasReachedMax: state is ClientSaleLoaded ? (state as ClientSaleLoaded).hasReachedMax : false,
    ));
  }
}

  _onUpdateClientSalesDocument(UpdateClientSalesDocument event, Emitter<ClientSaleState> emit) async {
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

      await Future.delayed(const Duration(milliseconds: 100));
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
