import 'package:crm_task_manager/models/mini_app_settiings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

part 'mini_app_settings_event.dart';
part 'mini_app_settings_state.dart';

class MiniAppSettingsBloc extends Bloc<MiniAppSettingsEvent, MiniAppSettingsState> {
  final ApiService apiService;

  MiniAppSettingsBloc(this.apiService) : super(MiniAppSettingsInitial()) {
    on<FetchMiniAppSettingsEvent>(_onFetchMiniAppSettings);
  }

  Future<void> _onFetchMiniAppSettings(
      FetchMiniAppSettingsEvent event, Emitter<MiniAppSettingsState> emit) async {
    emit(MiniAppSettingsLoading());
    try {
      final organizationId = await apiService.getSelectedOrganization();
      final settingsList = await apiService.getMiniAppSettings(organizationId);
      emit(MiniAppSettingsLoaded(settingsList));
    } catch (e) {
      emit(MiniAppSettingsError(e.toString()));
    }
  }
}