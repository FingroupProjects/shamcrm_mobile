import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'supplier_return_event.dart';
import 'supplier_return_state.dart';

class SupplierReturnBloc extends Bloc<SupplierReturnEvent, SupplierReturnState> {
  final ApiService apiService;
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic> _filters = {};
  List<IncomingDocument> _allData = [];

  SupplierReturnBloc(this.apiService) : super(SupplierReturnInitial()) {
    on<FetchSupplierReturn>(_onFetchSupplierReturn);
    on<CreateSupplierReturn>(_onCreateSupplierReturn);
    on<UpdateSupplierReturn>(_onUpdateSupplierReturn);
    on<DeleteSupplierReturn>(_onDeleteSupplierReturn);
    on<RestoreSupplierReturn>(_onRestoreSupplierReturn);
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
      emit(SupplierReturnRestoreError('Ошибка при восстановлении документа: ${e.toString()}'));
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

      emit(SupplierReturnLoaded(
        data: _allData,
        pagination: response.pagination,
        hasReachedMax: hasReachedMax,
      ));
    } catch (e) {
      emit(SupplierReturnError(e.toString()));
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
      );

      await Future.delayed(const Duration(milliseconds: 100));
      emit(SupplierReturnCreateSuccess('Документ успешно создан'));
    } catch (e) {
      emit(SupplierReturnCreateError(e.toString()));
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
      emit(SupplierReturnUpdateError(e.toString()));
    }
  }

  Future<void> _onDeleteSupplierReturn(DeleteSupplierReturn event, Emitter<SupplierReturnState> emit) async {
    emit(SupplierReturnDeleteLoading());
    try {
      final result = await apiService.deleteSupplierReturnDocument(event.documentId);
      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(SupplierReturnDeleteSuccess('Документ успешно удален'));
      } else {
        emit(SupplierReturnDeleteError('Не удалось удалить документ'));
      }
    } catch (e) {
      emit(SupplierReturnDeleteError('Ошибка при удалении документа: ${e.toString()}'));
    }
  }
}