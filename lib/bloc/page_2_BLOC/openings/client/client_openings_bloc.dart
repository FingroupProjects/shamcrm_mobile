import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import 'client_openings_event.dart';
import 'client_openings_state.dart';

class ClientOpeningsBloc extends Bloc<ClientOpeningsEvent, ClientOpeningsState> {
  final ApiService _apiService = ApiService();

  ClientOpeningsBloc() : super(ClientOpeningsInitial()) {
    on<LoadClientOpenings>(_onLoadClientOpenings);
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

      final response = await _apiService.getClientOpenings();

      final clients = response.result ?? [];
      
      emit(ClientOpeningsLoaded(clients: clients));
    } catch (e) {
      emit(ClientOpeningsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshClientOpenings(
    RefreshClientOpenings event,
    Emitter<ClientOpeningsState> emit,
  ) async {
    add(LoadClientOpenings());
  }

  Future<void> _onDeleteClientOpening(
    DeleteClientOpening event,
    Emitter<ClientOpeningsState> emit,
  ) async {
    try {
      await _apiService.deleteClientOpening(event.id);
      
      // Reload the list after successful deletion
      add(LoadClientOpenings());
    } catch (e) {
      // Сохраняем текущее состояние и эмитим операционную ошибку
      emit(ClientOpeningsOperationError(
        message: e.toString(),
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
      
      // Reload the list after successful creation
      add(LoadClientOpenings());
    } catch (e) {
      // Эмитим операционную ошибку для показа в snackbar
      emit(ClientOpeningsOperationError(
        message: e.toString(),
        previousState: state,
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
        leadId: event.leadId,
        ourDuty: event.ourDuty,
        debtToUs: event.debtToUs,
      );
      
      emit(ClientOpeningUpdateSuccess());
      
      // Reload the list after successful update
      add(LoadClientOpenings());
    } catch (e) {
      // Эмитим ошибку обновления для показа в snackbar
      emit(ClientOpeningUpdateError(
        message: e.toString(),
      ));
    }
  }
}
