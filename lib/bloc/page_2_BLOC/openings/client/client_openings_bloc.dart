import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/page_2/openings/client_openings_model.dart';
import 'client_openings_event.dart';
import 'client_openings_state.dart';

class ClientOpeningsBloc extends Bloc<ClientOpeningsEvent, ClientOpeningsState> {
  final ApiService _apiService = ApiService();

  ClientOpeningsBloc() : super(ClientOpeningsInitial()) {
    on<LoadClientOpenings>(_onLoadClientOpenings);
    on<RefreshClientOpenings>(_onRefreshClientOpenings);
  }

  Future<void> _onLoadClientOpenings(
    LoadClientOpenings event,
    Emitter<ClientOpeningsState> emit,
  ) async {
    try {
      if (event.page == 1) {
        emit(ClientOpeningsLoading());
      }

      final response = await _apiService.getClientOpenings(
        search: event.search,
        filter: event.filter,
      );

      final clients = response.result ?? [];
      
      if (event.page == 1) {
        emit(ClientOpeningsLoaded(
          clients: clients,
          hasReachedMax: clients.length < 20,
          pagination: Pagination(
            total: clients.length,
            count: clients.length,
            per_page: 20,
            current_page: 1,
            total_pages: 1,
          ),
        ));
      } else {
        final currentState = state as ClientOpeningsLoaded;
        final updatedClients = List<ClientOpening>.from(currentState.clients)
          ..addAll(clients);

        emit(currentState.copyWith(
          clients: updatedClients,
          hasReachedMax: clients.length < 20,
        ));
      }
    } catch (e) {
      if (event.page == 1) {
        emit(ClientOpeningsError(message: e.toString()));
      } else {
        emit(ClientOpeningsPaginationError(message: e.toString()));
      }
    }
  }

  Future<void> _onRefreshClientOpenings(
    RefreshClientOpenings event,
    Emitter<ClientOpeningsState> emit,
  ) async {
    add(LoadClientOpenings(
      page: 1,
      search: event.search,
      filter: event.filter,
    ));
  }
}
