// movement_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import '../../../../models/api_exception_model.dart';
import 'movement_event.dart';
import 'movement_state.dart';

class MovementBloc extends Bloc<MovementEvent, MovementState> {
  final ApiService apiService;
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic> _filters = {};
  List<IncomingDocument> _allData = [];
  List<IncomingDocument> _selectedDocuments = [];

  MovementBloc(this.apiService) : super(MovementInitial()) {
    on<FetchMovements>(_onFetchMovements);
    on<CreateMovementDocument>(_onCreateMovementDocument);
    on<UpdateMovementDocument>(_onUpdateMovementDocument);
    on<DeleteMovementDocument>(_onDeleteMovementDocument);
    on<RestoreMovementDocument>(_onRestoreMovementDocument);
    // Mass Operations
    on<MassApproveMovementDocuments>(_onMassApproveMovementDocuments);
    on<MassDisapproveMovementDocuments>(_onMassDisapproveMovementDocuments);
    on<MassDeleteMovementDocuments>(_onMassDeleteMovementDocuments);
    on<MassRestoreMovementDocuments>(_onMassRestoreMovementDocuments);

    // Selection
    on<SelectDocument>(_onSelectDocument);
    on<UnselectAllDocuments>(_onUnselectAllDocuments);
  }

  // Mass Operations Handlers
  Future<void> _onMassApproveMovementDocuments(MassApproveMovementDocuments event, Emitter<MovementState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == 0 && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massApproveMovementDocuments(ls);
      emit(MovementApproveMassSuccess("mass_approve_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MovementApproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MovementApproveMassError(e.toString()));
      }
      add(FetchMovements(forceRefresh: true));
    }

    emit(MovementLoaded(data: _allData));
  }

  Future<void> _onMassDisapproveMovementDocuments(MassDisapproveMovementDocuments event, Emitter<MovementState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == 1 && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massDisapproveMovementDocuments(ls);
      emit(MovementDisapproveMassSuccess("mass_disapprove_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MovementDisapproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MovementDisapproveMassError(e.toString()));
      }
      add(FetchMovements(forceRefresh: true));
    }

    emit(MovementLoaded(data: _allData));
  }

  Future<void> _onMassDeleteMovementDocuments(MassDeleteMovementDocuments event, Emitter<MovementState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massDeleteMovementDocuments(ls);
      emit(MovementDeleteMassSuccess("mass_delete_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MovementDeleteMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MovementDeleteMassError(e.toString()));
      }
      add(FetchMovements(forceRefresh: true));
    }

    emit(MovementLoaded(data: _allData));
  }

  Future<void> _onMassRestoreMovementDocuments(MassRestoreMovementDocuments event, Emitter<MovementState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt != null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massRestoreMovementDocuments(ls);
      emit(MovementRestoreMassSuccess("mass_restore_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(MovementRestoreMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(MovementRestoreMassError(e.toString()));
      }
      add(FetchMovements(forceRefresh: true));
    }

    emit(MovementLoaded(data: _allData));
  }

  // Selection Handlers
  Future<void> _onSelectDocument(SelectDocument event, Emitter<MovementState> emit) async {
    if (state is MovementLoaded) {
      final currentState = state as MovementLoaded;

      if (_selectedDocuments.contains(event.document)) {
        _selectedDocuments.remove(event.document);
      } else {
        _selectedDocuments.add(event.document);
      }

      final selectedDocuments = currentState.data
          .where((doc) => _selectedDocuments.contains(doc))
          .toList();

      emit(MovementLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: selectedDocuments,
      ));
    }
  }

  Future<void> _onUnselectAllDocuments(UnselectAllDocuments event, Emitter<MovementState> emit) async {
    _selectedDocuments = [];

    if (state is MovementLoaded) {
      final currentState = state as MovementLoaded;
      emit(MovementLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: [],
      ));
    }
  }

  Future<void> _onFetchMovements(FetchMovements event, Emitter<MovementState> emit) async {
    if (isClosed) return;

    if (event.forceRefresh) {
      _currentPage = 1;
      _allData = [];
      _filters = event.filters ?? {};
      if (!isClosed) {
        emit(MovementLoading());
      }
    } else if (state is MovementLoaded && (state as MovementLoaded).hasReachedMax) {
      return;
    }

    try {
      final response = await apiService.getMovementDocuments(
        page: _currentPage,
        perPage: _perPage,
        query: _filters['query'],
        fromDate: _filters['fromDate'],
        toDate: _filters['toDate'],
      );

      if (isClosed) return;

      final newData = response.data ?? [];
      _allData = event.forceRefresh ? newData : [..._allData, ...newData];

      final hasReachedMax = (response.pagination?.currentPage ?? 1) >= (response.pagination?.totalPages ?? 1);

      if (!hasReachedMax && newData.isNotEmpty) {
        _currentPage++;
      }

      final selectedDocuments = _allData
          .where((doc) => _selectedDocuments.contains(doc))
          .toList();

      if (!isClosed) {
        emit(MovementLoaded(
          data: _allData,
          pagination: response.pagination,
          hasReachedMax: hasReachedMax,
          selectedData: selectedDocuments,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        if (e is ApiException) {
          emit(MovementError(e.toString(), statusCode: e.statusCode));
        } else {
          emit(MovementError(e.toString()));
        }
      }
    }
  }

  Future<void> _onCreateMovementDocument(CreateMovementDocument event, Emitter<MovementState> emit) async {
    if (isClosed) return;

    emit(MovementCreateLoading());
    try {
      await apiService.createMovementDocument(
        date: event.date,
        senderStorageId: event.senderStorageId,
        recipientStorageId: event.recipientStorageId,
        comment: event.comment,
        documentGoods: event.documentGoods,
        organizationId: event.organizationId,
        approve: event.approve,
      );

      if (isClosed) return;

      await Future.delayed(const Duration(milliseconds: 100));

      if (!isClosed) {
        emit(MovementCreateSuccess(
            event.approve
                ? 'Документ успешно создан и проведен'
                : 'Документ успешно создан'
        ));
      }
    } catch (e) {
      if (!isClosed) {
        if (e is ApiException) {
          emit(MovementCreateError(e.toString(), statusCode: e.statusCode));
        } else {
          emit(MovementCreateError(e.toString()));
        }
      }
    }
  }

  Future<void> _onUpdateMovementDocument(UpdateMovementDocument event, Emitter<MovementState> emit) async {
    if (isClosed) return;

    emit(MovementUpdateLoading());
    try {
      await apiService.updateMovementDocument(
        documentId: event.documentId,
        date: event.date,
        senderStorageId: event.senderStorageId,
        recipientStorageId: event.recipientStorageId,
        comment: event.comment,
        documentGoods: event.documentGoods,
        organizationId: event.organizationId,
      );

      if (isClosed) return;

      await Future.delayed(const Duration(milliseconds: 100));

      if (!isClosed) {
        emit(MovementUpdateSuccess('Документ успешно обновлен'));
      }
    } catch (e) {
      if (!isClosed) {
        if (e is ApiException) {
          emit(MovementUpdateError(e.toString(), statusCode: e.statusCode));
        } else {
          emit(MovementUpdateError(e.toString()));
        }
      }
    }
  }

  Future<void> _onDeleteMovementDocument(DeleteMovementDocument event, Emitter<MovementState> emit) async {
    if (isClosed) return;

    if (event.shouldReload) emit(MovementDeleteLoading());

    try {
      await apiService.deleteMovementDocument(event.documentId);

      if (isClosed) return;

      await Future.delayed(const Duration(milliseconds: 100));

      if (!isClosed) {
        emit(MovementDeleteSuccess('Документ успешно удален', shouldReload: event.shouldReload || _allData.isEmpty));
      }
    } catch (e) {
      if (!isClosed) {
        if (e is ApiException) {
          emit(MovementDeleteError('Ошибка при удалении документа: ${e.toString()}', statusCode: e.statusCode));
        } else {
          emit(MovementDeleteError('Ошибка при удалении документа: ${e.toString()}'));
        }
      }
    }

    emit(MovementLoaded(data: _allData, selectedData: _selectedDocuments));
  }

  Future<void> _onRestoreMovementDocument(RestoreMovementDocument event, Emitter<MovementState> emit) async {
    if (isClosed) return;

    emit(MovementRestoreLoading());
    try {
      final result = await apiService.restoreMovementDocument(event.documentId);

      if (isClosed) return;

      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));

        if (!isClosed) {
          emit(MovementRestoreSuccess('Документ успешно восстановлен'));
        }
      } else {
        if (!isClosed) {
          emit(MovementRestoreError('Не удалось восстановить документ'));
        }
      }
    } catch (e) {
      if (!isClosed) {
        if (e is ApiException) {
          emit(MovementRestoreError('Ошибка при восстановлении документа: ${e.toString()}', statusCode: e.statusCode));
        } else {
          emit(MovementRestoreError('Ошибка при восстановлении документа: ${e.toString()}'));
        }
      }
    }
  }
}