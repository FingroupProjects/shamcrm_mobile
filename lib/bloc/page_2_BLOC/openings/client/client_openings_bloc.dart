import 'dart:async';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/openings/client_openings_model.dart';
import 'client_openings_event.dart';
import 'client_openings_state.dart';

class ClientOpeningsBloc extends Bloc<ClientOpeningsEvent, ClientOpeningsState> {
  final ApiService _apiService = ApiService();
  static const int _perPage = 20;

  int _currentPage = 1;
  int _loadToken = 0;
  List<ClientOpening> _allItems = [];
  String? _search;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;

  ClientOpeningsBloc() : super(ClientOpeningsInitial()) {
    on<LoadClientOpenings>(_onLoadClientOpenings);
    on<LoadMoreClientOpenings>(_onLoadMoreClientOpenings);
    on<RefreshClientOpenings>(_onRefreshClientOpenings);
    on<DeleteClientOpening>(_onDeleteClientOpening);
    on<CreateClientOpening>(_onCreateClientOpening);
    on<UpdateClientOpening>(_onUpdateClientOpening);
  }

  Future<void> _onLoadClientOpenings(
    LoadClientOpenings event,
    Emitter<ClientOpeningsState> emit,
  ) async {
    try {
      emit(ClientOpeningsLoading());

      _currentPage = 1;
      _search = event.search;
      _hasReachedMax = false;
      _isLoadingMore = false;
      final token = ++_loadToken;

      final response = await _apiService.getClientOpenings(
        search: event.search,
        page: _currentPage,
        perPage: _perPage,
      );
      if (token != _loadToken) return;

      final clients = response.result ?? [];
      _allItems = List.from(clients);
      _hasReachedMax = response.pagination?.reachedMax(
            fetchedCount: clients.length,
            perPage: _perPage,
          ) ??
          clients.length < _perPage;

      emit(ClientOpeningsLoaded(
        clients: List.from(_allItems),
        search: event.search,
        hasReachedMax: _hasReachedMax,
      ));
    } catch (e) {
      emit(ClientOpeningsError(message: friendlyError(e)));
    }
  }

  Future<void> _onLoadMoreClientOpenings(
    LoadMoreClientOpenings event,
    Emitter<ClientOpeningsState> emit,
  ) async {
    if (_isLoadingMore || _hasReachedMax) return;

    _isLoadingMore = true;
    final token = _loadToken;
    try {
      final nextPage = _currentPage + 1;
      final response = await _apiService.getClientOpenings(
        search: _search,
        page: nextPage,
        perPage: _perPage,
      );
      if (token != _loadToken) return;

      final clients = response.result ?? [];
      final existingIds = _allItems.map((e) => e.id).toSet();
      final uniqueClients =
          clients.where((item) => !existingIds.contains(item.id)).toList();
      _currentPage = nextPage;
      _allItems.addAll(uniqueClients);
      _hasReachedMax = uniqueClients.isEmpty ||
          (response.pagination?.reachedMax(
                fetchedCount: clients.length,
                perPage: _perPage,
              ) ??
              clients.length < _perPage);

      emit(ClientOpeningsLoaded(
        clients: List.from(_allItems),
        search: _search,
        hasReachedMax: _hasReachedMax,
      ));
    } catch (_) {
      // Keep the already loaded list visible.
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _onRefreshClientOpenings(
    RefreshClientOpenings event,
    Emitter<ClientOpeningsState> emit,
  ) async {
    // Сохраняем текущий search при обновлении
    final currentState = state;
    String? currentSearch;
    if (currentState is ClientOpeningsLoaded) {
      currentSearch = currentState.search;
    }
    add(LoadClientOpenings(search: currentSearch));
  }

  Future<void> _onDeleteClientOpening(
    DeleteClientOpening event,
    Emitter<ClientOpeningsState> emit,
  ) async {
    try {
      await _apiService.deleteClientOpening(event.id);
      
      // Emit success state
      emit(ClientOpeningDeleteSuccess());
      
      // Reload the list after successful deletion, сохраняем search
      final currentState = state;
      String? currentSearch;
      if (currentState is ClientOpeningsLoaded) {
        currentSearch = currentState.search;
      }
      add(LoadClientOpenings(search: currentSearch));
    } catch (e) {
      // Сохраняем текущее состояние и эмитим операционную ошибку
      emit(ClientOpeningsOperationError(
        message: friendlyError(e),
        previousState: state,
      ));
    }
  }

  Future<void> _onCreateClientOpening(
    CreateClientOpening event,
    Emitter<ClientOpeningsState> emit,
  ) async {
    try {
      // Эмитим состояние загрузки
      emit(ClientOpeningCreating());
      
      await _apiService.createClientOpening(
        leadId: event.leadId,
        ourDuty: event.ourDuty,
        debtToUs: event.debtToUs,
      );
      
      // Эмитим состояние успешного создания
      emit(ClientOpeningCreateSuccess());
      
      // Reload the list after successful creation, сохраняем search
      final currentState = state;
      String? currentSearch;
      if (currentState is ClientOpeningsLoaded) {
        currentSearch = currentState.search;
      }
      add(LoadClientOpenings(search: currentSearch));
    } catch (e) {
      // Эмитим ошибку создания
      emit(ClientOpeningCreateError(
        message: friendlyError(e),
      ));
    }
  }

  Future<void> _onUpdateClientOpening(
    UpdateClientOpening event,
    Emitter<ClientOpeningsState> emit,
  ) async {
    try {
      // Эмитим состояние загрузки
      emit(ClientOpeningUpdating());
      
      await _apiService.updateClientOpening(
        id: event.id,
        leadId: event.leadId,
        ourDuty: event.ourDuty,
        debtToUs: event.debtToUs,
      );
      
      emit(ClientOpeningUpdateSuccess());
      
      // Reload the list after successful update, сохраняем search
      final currentState = state;
      String? currentSearch;
      if (currentState is ClientOpeningsLoaded) {
        currentSearch = currentState.search;
      }
      add(LoadClientOpenings(search: currentSearch));
    } catch (e) {
      // Эмитим ошибку обновления для показа в snackbar
      emit(ClientOpeningUpdateError(
        message: friendlyError(e),
      ));
    }
  }
}
