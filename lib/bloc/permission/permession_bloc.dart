import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/widget_service.dart';
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
      
      // Sync permissions to iOS widget via App Groups
      await WidgetService.syncPermissionsToWidget(permissions);
      
      emit(PermissionsLoaded(permissionModels));
    } catch (e) {
      emit(PermissionsError('Ошибка при загрузке прав доступа!'));
    }
  }

  /// Получить список всех разрешений из текущего состояния
  List<String> getAllPermissions() {
    if (state is PermissionsLoaded) {
      final loadedState = state as PermissionsLoaded;
      // Извлекаем все разрешения из списка PermissionsModel
      return loadedState.permissions
          .expand((model) => model.permissions)
          .toList();
    }
    return [];
  }

  /// Проверить наличие конкретного разрешения
  bool hasPermission(String permission) {
    return getAllPermissions().contains(permission);
  }
}
