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

  MovementBloc(this.apiService) : super(MovementInitial()) {
    on<FetchMovements>(_onFetchMovements);
    on<CreateMovementDocument>(_onCreateMovementDocument);
    on<UpdateMovementDocument>(_onUpdateMovementDocument);
    on<DeleteMovementDocument>(_onDeleteMovementDocument);
    on<RestoreMovementDocument>(_onRestoreMovementDocument);
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

      if (!isClosed) {
        emit(MovementLoaded(
          data: _allData,
          pagination: response.pagination,
          hasReachedMax: hasReachedMax,
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
        approve: event.approve, // Передаем новый параметр
      );

      if (isClosed) return;

      await Future.delayed(const Duration(milliseconds: 100));

      if (!isClosed) {
        emit(MovementCreateSuccess('Документ успешно создан'));
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

    emit(MovementDeleteLoading());
    try {
      await apiService.deleteMovementDocument(event.documentId);

      if (isClosed) return;

      await Future.delayed(const Duration(milliseconds: 100));

      if (!isClosed) {
        emit(MovementDeleteSuccess('Документ успешно удален'));
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