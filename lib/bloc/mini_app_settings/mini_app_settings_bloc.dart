// lib/bloc/mini_app_settings/mini_app_settings_bloc.dart
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/mini_app_settiings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


abstract class MiniAppSettingsEvent {}
class FetchMiniAppSettingsEvent extends MiniAppSettingsEvent {
  final int organizationId;
  FetchMiniAppSettingsEvent(this.organizationId);
}

abstract class MiniAppSettingsState {}
class MiniAppSettingsInitial extends MiniAppSettingsState {}
class MiniAppSettingsLoading extends MiniAppSettingsState {}
class MiniAppSettingsLoaded extends MiniAppSettingsState {
  final List<MiniAppSettings> settings;
  MiniAppSettingsLoaded(this.settings);
}
class MiniAppSettingsError extends MiniAppSettingsState {
  final String message;
  MiniAppSettingsError(this.message);
}

class MiniAppSettingsBloc extends Bloc<MiniAppSettingsEvent, MiniAppSettingsState> {
  final ApiService apiService;

  MiniAppSettingsBloc(this.apiService) : super(MiniAppSettingsInitial()) {
    on<FetchMiniAppSettingsEvent>(_onFetchMiniAppSettings);
  }

  Future<void> _onFetchMiniAppSettings(
    FetchMiniAppSettingsEvent event,
    Emitter<MiniAppSettingsState> emit,
  ) async {
    emit(MiniAppSettingsLoading());
    try {
      final settingsList = await apiService.getMiniAppSettings(event.organizationId.toString());
      emit(MiniAppSettingsLoaded(settingsList));
    } catch (e) {
      emit(MiniAppSettingsError(e.toString()));
    }
  }
}