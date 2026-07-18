import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import '../../../../models/api_exception_model.dart';
import 'manufacture_event.dart';
import 'manufacture_state.dart';

class ManufactureBloc extends Bloc<ManufactureEvent, ManufactureState> {
  final ApiService apiService;
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic>? _filters;
  String? _search = '';
  List<IncomingDocument> _allData = [];
  List<IncomingDocument> _selectedDocuments = [];

  ManufactureBloc(this.apiService) : super(ManufactureInitial()) {
    on<FetchManufactures>(_onFetchManufactures);
    on<CreateManufactureDocument>(_onCreateManufactureDocument);
    on<UpdateManufactureDocument>(_onUpdateManufactureDocument);
    on<DeleteManufactureDocument>(_onDeleteManufactureDocument);
    on<RestoreManufactureDocument>(_onRestoreManufactureDocument);
    // Mass Operations
    on<MassApproveManufactureDocuments>(_onMassApproveManufactureDocuments);
    on<MassDisapproveManufactureDocuments>(
        _onMassDisapproveManufactureDocuments);
    on<MassDeleteManufactureDocuments>(_onMassDeleteManufactureDocuments);
    on<MassRestoreManufactureDocuments>(_onMassRestoreManufactureDocuments);
    // Selection
    on<SelectDocument>(_onSelectDocument);
    on<UnselectAllDocuments>(_onUnselectAllDocuments);
  }

  Future<void> _onFetchManufactures(
      FetchManufactures event, Emitter<ManufactureState> emit) async {
    if (isClosed) return;

    if (event.forceRefresh || _allData.isEmpty) {
      emit(ManufactureLoading());
    }

    if (event.forceRefresh) {
      _currentPage = 1;
      _allData.clear();
      _filters = event.filters;
      _search = event.search;
    } else if (state is ManufactureLoaded &&
        (state as ManufactureLoaded).hasReachedMax) {
      return;
    }

    try {
      final response = await apiService.getManufactureDocuments(
        page: _currentPage,
        perPage: _perPage,
        query: _search,
        fromDate: _filters?['date_from'],
        toDate: _filters?['date_to'],
        senderStorageId: _filters?['storage_id'] != null
            ? int.tryParse(_filters!['storage_id'].toString())
            : null,
        recipientStorageId: _filters?['recipient_storage_id'] != null
            ? int.tryParse(_filters!['recipient_storage_id'].toString())
            : null,
        status: _filters?['status'] != null
            ? int.tryParse(_filters!['status'].toString())
            : null,
        authorId: _filters?['author_id'] != null
            ? int.tryParse(_filters!['author_id'].toString())
            : null,
        deleted: _filters?['deleted'] != null
            ? int.tryParse(_filters!['deleted'].toString())
            : null,
      );

      if (isClosed) return;

      final newData = response.data ?? [];

      if (event.forceRefresh) {
        _allData = List.from(newData);
      } else {
        _allData.addAll(newData);
      }

      final hasReachedMax = (response.pagination?.currentPage ?? 1) >=
          (response.pagination?.totalPages ?? 1);

      if (!hasReachedMax && newData.isNotEmpty) {
        _currentPage++;
      }

      final selectedDocuments =
          _allData.where((doc) => _selectedDocuments.contains(doc)).toList();

      if (!isClosed) {
        emit(ManufactureLoaded(
          data: List.from(_allData),
          pagination: response.pagination,
          hasReachedMax: hasReachedMax,
          selectedData: selectedDocuments,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        if (e is ApiException) {
          emit(ManufactureError(friendlyError(e), statusCode: e.statusCode));
        } else {
          emit(ManufactureError(friendlyError(e)));
        }
      }
    }
  }

  Future<void> _onCreateManufactureDocument(
      CreateManufactureDocument event, Emitter<ManufactureState> emit) async {
    if (isClosed) return;

    emit(ManufactureCreateLoading());
    try {
      await apiService.createManufactureDocument(
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
        emit(ManufactureCreateSuccess(
          event.approve
              ? 'Документ успешно создан и проведен'
              : 'Документ успешно создан',
        ));
      }
    } catch (e) {
      if (!isClosed) {
        if (e is ApiException) {
          emit(ManufactureCreateError(friendlyError(e), statusCode: e.statusCode));
        } else {
          emit(ManufactureCreateError(friendlyError(e)));
        }
      }
    }
  }

  Future<void> _onUpdateManufactureDocument(
      UpdateManufactureDocument event, Emitter<ManufactureState> emit) async {
    if (isClosed) return;

    emit(ManufactureUpdateLoading());
    try {
      await apiService.updateManufactureDocument(
        documentId: event.documentId,
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
        emit(ManufactureUpdateSuccess(
          event.approve
              ? 'Документ успешно обновлен и проведен'
              : 'Документ успешно обновлен',
        ));
      }
    } catch (e) {
      if (!isClosed) {
        if (e is ApiException) {
          emit(ManufactureUpdateError(friendlyError(e), statusCode: e.statusCode));
        } else {
          emit(ManufactureUpdateError(friendlyError(e)));
        }
      }
    }
  }

  Future<void> _onDeleteManufactureDocument(
      DeleteManufactureDocument event, Emitter<ManufactureState> emit) async {
    if (isClosed) return;

    final isLastElement = _allData.length == 1;

    if (event.shouldReload || isLastElement) {
      emit(ManufactureDeleteLoading());
    }

    try {
      final result =
          await apiService.deleteManufactureDocument(event.documentId);

      if (isClosed) return;

      if (result['result'] == 'Success') {
        // ✅ Удаляем из локального состояния
        _allData.removeWhere((doc) => doc.id == event.documentId);
        _selectedDocuments.removeWhere((doc) => doc.id == event.documentId);

        if (!isClosed) {
          emit(ManufactureDeleteSuccess('Документ успешно удален',
              shouldReload: event.shouldReload || isLastElement));
        }
      } else {
        if (!isClosed) {
          emit(ManufactureDeleteError('Не удалось удалить документ'));
        }
      }
    } catch (e) {
      if (!isClosed) {
        if (e is ApiException) {
          emit(ManufactureDeleteError(
              'Ошибка при удалении документа: ${e.toString()}',
              statusCode: e.statusCode));
        } else {
          emit(ManufactureDeleteError(
              'Ошибка при удалении документа: ${e.toString()}'));
        }
      }
    }
  }

  Future<void> _onRestoreManufactureDocument(
      RestoreManufactureDocument event, Emitter<ManufactureState> emit) async {
    if (isClosed) return;

    emit(ManufactureRestoreLoading());
    try {
      final result =
          await apiService.restoreManufactureDocument(event.documentId);

      if (isClosed) return;

      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));

        if (!isClosed) {
          emit(ManufactureRestoreSuccess('Документ успешно восстановлен'));
        }
      } else {
        if (!isClosed) {
          emit(ManufactureRestoreError('Не удалось восстановить документ'));
        }
      }
    } catch (e) {
      if (!isClosed) {
        if (e is ApiException) {
          emit(ManufactureRestoreError(
              'Ошибка при восстановлении документа: ${e.toString()}',
              statusCode: e.statusCode));
        } else {
          emit(ManufactureRestoreError(
              'Ошибка при восстановлении документа: ${e.toString()}'));
        }
      }
    }
  }

  Future<void> _onMassApproveManufactureDocuments(
      MassApproveManufactureDocuments event,
      Emitter<ManufactureState> emit) async {
    if (isClosed) return;

    final ls = _selectedDocuments
        .where((e) => e.approved == 0 && e.deletedAt == null)
        .map((e) => e.id!)
        .toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massApproveManufactureDocuments(ls);
      if (!isClosed) {
        emit(ManufactureApproveMassSuccess("Документы успешно проведены"));
      }
    } catch (e) {
      if (!isClosed) {
        if (e is ApiException && e.statusCode == 409) {
          emit(ManufactureApproveMassError(friendlyError(e),
              statusCode: e.statusCode));
        } else {
          emit(ManufactureApproveMassError(friendlyError(e)));
        }
        add(FetchManufactures(
            forceRefresh: true, filters: _filters, search: _search));
      }
    }

    if (!isClosed) {
      emit(ManufactureLoaded(data: _allData, selectedData: _selectedDocuments));
    }
  }

  Future<void> _onMassDisapproveManufactureDocuments(
      MassDisapproveManufactureDocuments event,
      Emitter<ManufactureState> emit) async {
    if (isClosed) return;

    final ls = _selectedDocuments
        .where((e) => e.approved == 1 && e.deletedAt == null)
        .map((e) => e.id!)
        .toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massDisapproveManufactureDocuments(ls);
      if (!isClosed) {
        emit(ManufactureDisapproveMassSuccess(
            "Документы успешно сняты с проведения"));
      }
    } catch (e) {
      if (!isClosed) {
        if (e is ApiException && e.statusCode == 409) {
          emit(ManufactureDisapproveMassError(friendlyError(e),
              statusCode: e.statusCode));
        } else {
          emit(ManufactureDisapproveMassError(friendlyError(e)));
        }
        add(FetchManufactures(
            forceRefresh: true, filters: _filters, search: _search));
      }
    }

    if (!isClosed) {
      emit(ManufactureLoaded(data: _allData, selectedData: _selectedDocuments));
    }
  }

  Future<void> _onMassDeleteManufactureDocuments(
      MassDeleteManufactureDocuments event,
      Emitter<ManufactureState> emit) async {
    if (isClosed) return;

    final ls = _selectedDocuments
        .where((e) => e.deletedAt == null)
        .map((e) => e.id!)
        .toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massDeleteManufactureDocuments(ls);

      // ✅ Удаляем из локального состояния
      _allData.removeWhere((doc) => ls.contains(doc.id));

      if (!isClosed) {
        emit(ManufactureDeleteMassSuccess("Документы успешно удалены"));
      }
    } catch (e) {
      if (!isClosed) {
        if (e is ApiException && e.statusCode == 409) {
          emit(ManufactureDeleteMassError(friendlyError(e),
              statusCode: e.statusCode));
        } else {
          emit(ManufactureDeleteMassError(friendlyError(e)));
        }
        add(FetchManufactures(
            forceRefresh: true, filters: _filters, search: _search));
      }
    }

    if (!isClosed) {
      emit(ManufactureLoaded(
          data: List.from(_allData),
          selectedData: List.from(_selectedDocuments)));
    }
  }

  Future<void> _onMassRestoreManufactureDocuments(
      MassRestoreManufactureDocuments event,
      Emitter<ManufactureState> emit) async {
    if (isClosed) return;

    final ls = _selectedDocuments
        .where((e) => e.deletedAt != null)
        .map((e) => e.id!)
        .toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massRestoreManufactureDocuments(ls);
      if (!isClosed) {
        emit(ManufactureRestoreMassSuccess("Документы успешно восстановлены"));
      }
    } catch (e) {
      if (!isClosed) {
        if (e is ApiException && e.statusCode == 409) {
          emit(ManufactureRestoreMassError(friendlyError(e),
              statusCode: e.statusCode));
        } else {
          emit(ManufactureRestoreMassError(friendlyError(e)));
        }
        add(FetchManufactures(
            forceRefresh: true, filters: _filters, search: _search));
      }
    }

    if (!isClosed) {
      emit(ManufactureLoaded(data: _allData, selectedData: _selectedDocuments));
    }
  }

  Future<void> _onSelectDocument(
      SelectDocument event, Emitter<ManufactureState> emit) async {
    if (isClosed) return;

    if (state is ManufactureLoaded) {
      final currentState = state as ManufactureLoaded;

      if (_selectedDocuments.contains(event.document)) {
        _selectedDocuments.remove(event.document);
      } else {
        _selectedDocuments.add(event.document);
      }

      final selectedDocuments = currentState.data
          .where((doc) => _selectedDocuments.contains(doc))
          .toList();

      if (!isClosed) {
        emit(ManufactureLoaded(
          data: currentState.data,
          pagination: currentState.pagination,
          hasReachedMax: currentState.hasReachedMax,
          selectedData: selectedDocuments,
        ));
      }
    }
  }

  Future<void> _onUnselectAllDocuments(
      UnselectAllDocuments event, Emitter<ManufactureState> emit) async {
    if (isClosed) return;

    _selectedDocuments = [];

    if (state is ManufactureLoaded) {
      final currentState = state as ManufactureLoaded;
      if (!isClosed) {
        emit(ManufactureLoaded(
          data: currentState.data,
          pagination: currentState.pagination,
          hasReachedMax: currentState.hasReachedMax,
          selectedData: [],
        ));
      }
    }
  }
}
