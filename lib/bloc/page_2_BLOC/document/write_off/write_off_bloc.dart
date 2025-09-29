import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/api_exception_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';

part 'write_off_event.dart';
part 'write_off_state.dart';

class WriteOffBloc extends Bloc<WriteOffEvent, WriteOffState> {
  final ApiService apiService;
  int _currentPage = 1;
  final int _perPage = 20;
  Map<String, dynamic>? _filters;
  String? _search = '';
  List<IncomingDocument> _allData = [];
  List<IncomingDocument> _selectedDocuments = [];

  WriteOffBloc(this.apiService) : super(WriteOffInitial()) {
    on<FetchWriteOffs>(_onFetchData);
    on<CreateWriteOffDocument>(_onCreateWriteOffDocument);
    on<DeleteWriteOffDocument>(_onDeleteWriteOff);
    on<UpdateWriteOffDocument>(_onUpdateWriteOffDocument);
    on<RestoreWriteOff>(_onRestoreWriteOff);

    on<MassApproveWriteOffDocuments>(_onMassApproveWriteOffDocuments);
    on<MassDisapproveWriteOffDocuments>(_onMassDisapproveWriteOffDocuments);
    on<MassDeleteWriteOffDocuments>(_onMassDeleteWriteOffDocuments);
    on<MassRestoreWriteOffDocuments>(_onMassRestoreWriteOffDocuments);

    on<SelectDocument>(_onSelectDocument);
    on<UnselectAllDocuments>(_onUnselectAllDocuments);
  }

  Future<void> _onMassApproveWriteOffDocuments(MassApproveWriteOffDocuments event, Emitter<WriteOffState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == 0 && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massApproveWriteOffDocuments(ls);
      emit(WriteOffApproveMassSuccess("mass_approve_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(WriteOffApproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(WriteOffApproveMassError(e.toString()));
      }
      add(FetchWriteOffs(forceRefresh: true));
    }

    emit(WriteOffLoaded(data: _allData));
  }

  Future<void> _onMassDisapproveWriteOffDocuments(MassDisapproveWriteOffDocuments event, Emitter<WriteOffState> emit) async {
    final ls = _selectedDocuments.where((e) => e.approved == 1 && e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massDisapproveWriteOffDocuments(ls);
      emit(WriteOffDisapproveMassSuccess("mass_disapprove_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(WriteOffDisapproveMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(WriteOffDisapproveMassError(e.toString()));
      }
      add(FetchWriteOffs(forceRefresh: true));
    }

    emit(WriteOffLoaded(data: _allData));
  }

  Future<void> _onMassDeleteWriteOffDocuments(MassDeleteWriteOffDocuments event, Emitter<WriteOffState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt == null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massDeleteWriteOffDocuments(ls);
      emit(WriteOffDeleteMassSuccess("mass_delete_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(WriteOffDeleteMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(WriteOffDeleteMassError(e.toString()));
      }
      add(FetchWriteOffs(forceRefresh: true));
    }

    emit(WriteOffLoaded(data: _allData));
  }

  Future<void> _onMassRestoreWriteOffDocuments(MassRestoreWriteOffDocuments event, Emitter<WriteOffState> emit) async {
    final ls = _selectedDocuments.where((e) => e.deletedAt != null).map((e) => e.id!).toList();
    add(UnselectAllDocuments());

    try {
      await apiService.massRestoreWriteOffDocuments(ls);
      emit(WriteOffRestoreMassSuccess("mass_restore_success_message"));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(WriteOffRestoreMassError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(WriteOffRestoreMassError(e.toString()));
      }
      add(FetchWriteOffs(forceRefresh: true));
    }

    emit(WriteOffLoaded(data: _allData));
  }

  Future<void> _onSelectDocument(SelectDocument event, Emitter<WriteOffState> emit) async {
    if (state is WriteOffLoaded) {
      final currentState = state as WriteOffLoaded;

      if (_selectedDocuments.contains(event.document)) {
        _selectedDocuments.remove(event.document);
      } else {
        _selectedDocuments.add(event.document);
      }

      final selectedDocuments = currentState.data
          .where((doc) => _selectedDocuments.contains(doc))
          .toList();

      emit(WriteOffLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: selectedDocuments,
      ));
    }
  }

  Future<void> _onUnselectAllDocuments(UnselectAllDocuments event, Emitter<WriteOffState> emit) async {
    _selectedDocuments = [];

    if (state is WriteOffLoaded) {
      final currentState = state as WriteOffLoaded;
      emit(WriteOffLoaded(
        data: currentState.data,
        pagination: currentState.pagination,
        hasReachedMax: currentState.hasReachedMax,
        selectedData: [],
      ));
    }
  }

  Future<void> _onRestoreWriteOff(RestoreWriteOff event, Emitter<WriteOffState> emit) async {
    emit(WriteOffRestoreLoading());
    try {
      final result = await apiService.restoreWriteOffDocument(event.documentId);
      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(WriteOffRestoreSuccess('Документ успешно восстановлен'));
      } else {
        emit(WriteOffRestoreError('Не удалось восстановить документ'));
      }
    } catch (e) {
      if (e is ApiException) {
        emit(WriteOffRestoreError('Ошибка при восстановлении документа: ${e.toString()}', statusCode: e.statusCode));
      } else {
        emit(WriteOffRestoreError('Ошибка при восстановлении документа: ${e.toString()}'));
      }
    }
  }

  Future<void> _onFetchData(FetchWriteOffs event, Emitter<WriteOffState> emit) async {
    if (event.forceRefresh || _allData.isEmpty) {
      emit(WriteOffLoading());
    }

    if (event.forceRefresh) {
      _currentPage = 1;
      _allData.clear();
      _filters = event.filters;
      _search = event.search;
    } else if (state is WriteOffLoaded && (state as WriteOffLoaded).hasReachedMax) {
      return;
    }

    try {
      final response = await apiService.getWriteOffDocuments(
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

      emit(WriteOffLoaded(
        data: List.from(_allData),
        pagination: response.pagination,
        hasReachedMax: hasReachedMax,
        selectedData: selectedDocuments,
      ));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        emit(WriteOffError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(WriteOffError(e.toString()));
      }
    }
  }

  Future<void> _onCreateWriteOffDocument(CreateWriteOffDocument event, Emitter<WriteOffState> emit) async {
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
      await Future.delayed(const Duration(milliseconds: 100));
      emit(WriteOffCreateSuccess(
          event.approve
              ? 'Документ успешно создан и проведен'
              : 'Документ успешно создан'
      ));
    } catch (e) {
      if (e is ApiException) {
        emit(WriteOffCreateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(WriteOffCreateError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteWriteOff(DeleteWriteOffDocument event, Emitter<WriteOffState> emit) async {
    if(event.shouldReload) emit(WriteOffDeleteLoading());
    try {
      final result = await apiService.deleteWriteOffDocument(event.documentId);
      if (result['result'] == 'Success') {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(WriteOffDeleteSuccess('Документ успешно удален', shouldReload: event.shouldReload || _allData.isEmpty));
      } else {
        emit(WriteOffDeleteError('Не удалось удалить документ'));
      }
    } catch (e) {
      if (e is ApiException) {
        emit(WriteOffDeleteError('Ошибка при удалении документа: ${e.toString()}', statusCode: e.statusCode));
      } else {
        emit(WriteOffDeleteError('Ошибка при удалении документа: ${e.toString()}'));
      }
    }
    emit(WriteOffLoaded(data: _allData, selectedData: _selectedDocuments));
  }

  Future<void> _onUpdateWriteOffDocument(UpdateWriteOffDocument event, Emitter<WriteOffState> emit) async {
    emit(WriteOffUpdateLoading());
    try {
      await apiService.updateWriteOffDocument(
        documentId: event.documentId,
        date: event.date,
        storageId: event.storageId,
        comment: event.comment,
        documentGoods: event.documentGoods,
        organizationId: event.organizationId,
      );
      await Future.delayed(const Duration(milliseconds: 100));
      emit(WriteOffUpdateSuccess('Документ успешно обновлен'));
    } catch (e) {
      if (e is ApiException) {
        emit(WriteOffUpdateError(e.toString(), statusCode: e.statusCode));
      } else {
        emit(WriteOffUpdateError(e.toString()));
      }
    }
  }
}