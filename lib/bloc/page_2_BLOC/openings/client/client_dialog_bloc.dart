import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import 'client_dialog_event.dart';
import 'client_dialog_state.dart';

class ClientDialogBloc extends Bloc<ClientDialogEvent, ClientDialogState> {
  final ApiService _apiService = ApiService();

  ClientDialogBloc() : super(ClientDialogInitial()) {
    on<LoadLeadsForDialog>(_onLoadLeadsForDialog);
  }

  Future<void> _onLoadLeadsForDialog(
    LoadLeadsForDialog event,
    Emitter<ClientDialogState> emit,
  ) async {
    try {
      emit(ClientDialogLoading());
      
      final leads = await _apiService.getClientOpeningsForDialog();
      
      emit(ClientDialogLoaded(leads: leads));
    } catch (e) {
      emit(ClientDialogError(message: e.toString()));
    }
  }
}

