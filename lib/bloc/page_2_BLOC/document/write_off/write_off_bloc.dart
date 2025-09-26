import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/api_exception_model.dart';

part 'write_off_event.dart';
part 'write_off_state.dart';

class WriteOffBloc extends Bloc<WriteOffEvent, WriteOffState> {
  final ApiService apiService;
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic> _filters = {};
  List<IncomingDocument> _allData = [];

  WriteOffBloc(this.apiService) : super(WriteOffInitial()) {
    on<FetchWriteOffs>(_onFetchData);
    on<CreateWriteOffDocument>(_onCreateWriteOffDocument);
    on<DeleteWriteOffDocument>(_delete);
    on<UpdateWriteOffDocument>(_onUpdateWriteOffDocument);
  }

  _onFetchData(FetchWriteOffs event, Emitter<WriteOffState> emit) async {
    if (event.forceRefresh) {
      _currentPage = 1;
      _allData = [];
      _filters = event.filters ?? {};
      emit(WriteOffLoading());
    } else if (state is WriteOffLoaded &&
        (state as WriteOffLoaded).hasReachedMax) {
      return; // Не делаем запрос, если достигнут конец
    }

    try {
      final response = await apiService.getWriteOffDocuments(
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

      emit(WriteOffLoaded(
        data: _allData,
        pagination: response.pagination,
        hasReachedMax: hasReachedMax,
      ));
    } catch (e) {
      if (e is ApiException && e.statusCode != null) {
        emit(WriteOffError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(WriteOffError(e.toString()));
      }
    }
  }

  _onCreateWriteOffDocument(CreateWriteOffDocument event, Emitter<WriteOffState> emit) async {
    emit(WriteOffCreateLoading());
    try {
      await apiService.createWriteOffDocument(
        date: event.date,
        storageId: event.storageId,
        comment: event.comment,
        documentGoods: event.documentGoods,
        organizationId: event.organizationId,
        approve: event.approve,
      );
      emit(WriteOffCreateSuccess('Документ успешно создан'));
    } catch (e) {
      if (e is ApiException && e.statusCode != null) {
        emit(WriteOffCreateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(WriteOffCreateError(e.toString()));
      }
    }
  }

  _delete(DeleteWriteOffDocument event, Emitter<WriteOffState> emit) async {
    try {
      await apiService.deleteWriteOffDocument(event.documentId);
      add(FetchWriteOffs(forceRefresh: true, filters: _filters));
    } catch (e) {
      if (e is ApiException && e.statusCode != null) {
        emit(WriteOffError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(WriteOffError(e.toString()));
      }
    }
  }

  _onUpdateWriteOffDocument(
      UpdateWriteOffDocument event, Emitter<WriteOffState> emit) async {
    emit(WriteOffCreateLoading());
    try {
      await apiService.updateWriteOffDocument(
        documentId: event.documentId,
        date: event.date,
        storageId: event.storageId,
        comment: event.comment,
        documentGoods: event.documentGoods,
        organizationId: event.organizationId,
      );
      emit(WriteOffUpdateSuccess('Документ успешно обновлен'));
    } catch (e) {
      if (e is ApiException && e.statusCode != null) {
        emit(WriteOffUpdateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(WriteOffUpdateError(e.toString()));
      }
    }
  }
}