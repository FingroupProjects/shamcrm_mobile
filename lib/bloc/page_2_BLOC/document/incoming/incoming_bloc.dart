import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'incoming_event.dart';
import 'incoming_state.dart';

class IncomingBloc extends Bloc<IncomingEvent, IncomingState> {
  final ApiService apiService;
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic> _filters = {};
  List<IncomingDocument> _allData = [];

  IncomingBloc(this.apiService) : super(IncomingInitial()) {
    on<FetchIncoming>(_onFetchIncoming);
    on<CreateIncoming>(_onCreateIncoming);
  }

  Future<void> _onFetchIncoming(FetchIncoming event, Emitter<IncomingState> emit) async {
    if (event.forceRefresh) {
      _currentPage = 1;
      _allData = [];
      _filters = event.filters ?? {};
      emit(IncomingLoading());
    } else if (state is IncomingLoaded && (state as IncomingLoaded).hasReachedMax) {
      return; // Не делаем запрос, если достигнут конец
    }

    try {
      final response = await apiService.getIncomingDocuments(
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

      emit(IncomingLoaded(
        data: _allData,
        pagination: response.pagination,
        hasReachedMax: hasReachedMax,
      ));
    } catch (e) {
      emit(IncomingError(e.toString()));
    }
  }

   Future<void> _onCreateIncoming(CreateIncoming event, Emitter<IncomingState> emit) async {
    emit(IncomingCreateLoading());
    try {
      final response = await apiService.createIncomingDocument(
        date: event.date,
        storageId: event.storageId,
        comment: event.comment,
        counterpartyId: event.counterpartyId,
        documentGoods: event.documentGoods,
        organizationId: event.organizationId,
        salesFunnelId: event.salesFunnelId,
      );
      emit(IncomingCreateSuccess('Документ успешно создан'));
      add(const FetchIncoming(forceRefresh: true)); // Обновляем список после создания
    } catch (e) {
      emit(IncomingCreateError(e.toString()));
    }
  }


}