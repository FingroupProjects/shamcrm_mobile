import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/permission/permession_event.dart';
import 'package:crm_task_manager/bloc/permission/permession_state.dart';
import 'package:crm_task_manager/models/permission.dart';

class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  final ApiService apiService;

  PermissionsBloc(this.apiService) : super(PermissionsInitial()) {
    on<FetchPermissionsEvent>(_fetchPermissions);
  }

  Future<void> _fetchPermissions(
      FetchPermissionsEvent event, Emitter<PermissionsState> emit) async {
    emit(PermissionsLoading());
    try {
      final permissions = await apiService.fetchPermissionsByRoleId();

      List<PermissionsModel> permissionModels = permissions
          .map((permission) => PermissionsModel(permissions: [permission]))
          .toList();

      await apiService.savePermissions(permissions);
      emit(PermissionsLoaded(permissionModels));
    } catch (e) {
      emit(PermissionsError('Ошибка при загрузке прав доступа!'));
    }
  }
}
