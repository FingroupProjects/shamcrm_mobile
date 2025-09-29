import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import '../../../../models/api_exception_model.dart';
import 'incoming_event.dart';
import 'incoming_state.dart';

class IncomingBloc extends Bloc<IncomingEvent, IncomingState> {
  final ApiService apiService;
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic>? _filters;
  String? _search = '';
  List<IncomingDocument> _allData = [];
  List<IncomingDocument> _selectedDocuments = [];

  IncomingBloc(this.apiService) : super(IncomingInitial()) {
    on<FetchIncoming>(_onFetchIncoming);
    on<CreateIncoming>(_onCreateIncoming);
    on<UpdateIncoming>(_onUpdateIncoming);
    on<DeleteIncoming>(_onDeleteIncoming);  // Добавьте эту строку
    on<RestoreIncoming>(_onRestoreIncoming); // Добавить эту строку

    on<MassApproveIncomingDocuments>(_onMassApproveIncomingDocuments);
    on<MassDisapproveIncomingDocuments>(_onMassDisapproveIncomingDocuments);
    on<MassDeleteIncomingDocuments>(_onMassDeleteIncomingDocuments);
    on<MassRestoreIncomingDocuments>(_onMassRestoreIncomingDocuments);

    on<SelectDocument>(_onSelectDocument);
    on<UnselectAllDocuments>(_onUnselectAllDocuments);
  }


  Future<void> _onMassApproveIncomingDocuments(MassApproveIncomingDocuments event, Emitter<IncomingState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == 0 && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massApproveIncomingDocuments(ls);
      emit(IncomingApproveMassSuccess("mass_approve_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(IncomingApproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(IncomingApproveMassError(e.toString()));
      }
      add(FetchIncoming(forceRefresh: true));
    }

    emit(IncomingLoaded(data: _allData));
  }

  Future<void> _onMassDisapproveIncomingDocuments(MassDisapproveIncomingDocuments event, Emitter<IncomingState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == 1 && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massDisapproveIncomingDocuments(ls);
      emit(IncomingDisapproveMassSuccess("mass_disapprove_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(IncomingDisapproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(IncomingDisapproveMassError(e.toString()));
      }
      add(FetchIncoming(forceRefresh: true));
    }

    emit(IncomingLoaded(data: _allData));
  }

  Future<void> _onMassDeleteIncomingDocuments(MassDeleteIncomingDocuments event, Emitter<IncomingState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massDeleteIncomingDocuments(ls);
      emit(IncomingDeleteMassSuccess("mass_delete_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(IncomingDeleteMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(IncomingDeleteMassError(e.toString()));
      }
      add(FetchIncoming(forceRefresh: true));
    }

    emit(IncomingLoaded(data: _allData));
  }

  Future<void> _onMassRestoreIncomingDocuments(MassRestoreIncomingDocuments event, Emitter<IncomingState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt != null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massRestoreIncomingDocuments(ls);
      emit(IncomingRestoreMassSuccess("mass_restore_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(IncomingRestoreMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(IncomingRestoreMassError(e.toString()));
      }
      add(FetchIncoming(forceRefresh: true));
    }

    emit(IncomingLoaded(data: _allData));
  }


  Future<void> _onSelectDocument(SelectDocument event, Emitter<IncomingState> emit) async {
    if (state is IncomingLoaded) {
      final currentState = state as IncomingLoaded;

      if (_selectedDocuments.contains(event.document)) {
        _selectedDocuments.remove(event.document);
      } else {
        _selectedDocuments.add(event.document);
      }

      final selectedDocuments = currentState.data
          .where((doc) => _selectedDocuments.contains(doc))
          .toList();

      emit(IncomingLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: selectedDocuments,
      ));
    }
  }

  Future<void> _onUnselectAllDocuments(UnselectAllDocuments event, Emitter<IncomingState> emit) async {
    _selectedDocuments = [];

    if (state is IncomingLoaded) {
      final currentState = state as IncomingLoaded;
      emit(IncomingLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: [],
      ));
    }
  }

  /////////////

  Future<void> _onRestoreIncoming(RestoreIncoming event, Emitter<IncomingState> emit) async {
    emit(IncomingRestoreLoading());
    try {
      final result = await apiService.restoreIncomingDocument(event.documentId);
      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(IncomingRestoreSuccess('Документ успешно восстановлен'));
      } else {
        emit(IncomingRestoreError('Не удалось восстановить документ'));
      }
    } catch (e) {
      if (e is ApiException) {
        emit(IncomingRestoreError('Ошибка при восстановлении документа: ${e.toString()}', statusCode: e.statusCode));
      } else {
        emit(IncomingRestoreError('Ошибка при восстановлении документа: ${e.toString()}'));
      }
    }
  }

  Future<void> _onFetchIncoming(FetchIncoming event, Emitter<IncomingState> emit) async {
    if (event.forceRefresh || _allData.isEmpty) {
      emit(IncomingLoading());
    }

    if (event.forceRefresh) {
      _currentPage = 1;
      _allData.clear();
      _filters = event.filters;
      _search = event.search;
    } else if (state is IncomingLoaded && (state as IncomingLoaded).hasReachedMax) {
      return;
    }

    try {
      final response = await apiService.getIncomingDocuments(
        page: _currentPage,
        perPage: _perPage,
        filters: _filters,
        search: _search,
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

      final selectedDocuments = _allData
          .where((doc) => _selectedDocuments.contains(doc))
          .toList();

      emit(IncomingLoaded(
        data: List.from(_allData),
        pagination: response.pagination,
        hasReachedMax: hasReachedMax,
        selectedData: selectedDocuments,
      ));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(IncomingError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(IncomingError(e.toString()));
      }
    }
  }

  Future<void> _onCreateIncoming(CreateIncoming event, Emitter<IncomingState> emit) async {
    emit(IncomingCreateLoading());
    try {
      await apiService.createIncomingDocument(
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
      emit(IncomingCreateSuccess(
          event.approve
              ? 'Документ успешно создан и проведен'
              : 'Документ успешно создан'
      ));
    } catch (e) {
      if (e is ApiException) {
        emit(IncomingCreateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(IncomingCreateError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateIncoming(UpdateIncoming event, Emitter<IncomingState> emit) async {
    emit(IncomingUpdateLoading());
    try {
      await apiService.updateIncomingDocument(
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
      emit(IncomingUpdateSuccess('Документ успешно обновлен'));
    } catch (e) {
      if (e is ApiException) {
        emit(IncomingUpdateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(IncomingUpdateError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteIncoming(DeleteIncoming event, Emitter<IncomingState> emit) async {
    if(event.shouldReload) emit(IncomingDeleteLoading()); // Эта строка должна быть!
    try {
      final result = await apiService.deleteIncomingDocument(event.documentId);
      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(IncomingDeleteSuccess('Документ успешно удален', shouldReload: event.shouldReload || _allData.isEmpty));
      } else {
        emit(IncomingDeleteError('Не удалось удалить документ'));
      }
    } catch (e) {
      if (e is ApiException) {
        emit(IncomingDeleteError('Ошибка при удалении документа: ${e.toString()}', statusCode: e.statusCode));
      } else {
        emit(IncomingDeleteError('Ошибка при удалении документа: ${e.toString()}'));
      }
    }
    emit(IncomingLoaded(data: _allData, selectedData: _selectedDocuments));
  }
}