import 'package:crm_task_manager/models/permission.dart';

abstract class PermissionsState {}

class PermissionsInitial extends PermissionsState {}

class PermissionsLoading extends PermissionsState {}

class PermissionsLoaded extends PermissionsState {
  final List<PermissionsModel> permissions;

  PermissionsLoaded(this.permissions);
}

class PermissionCheckResult extends PermissionsState {
  final bool hasPermission;

  PermissionCheckResult(this.hasPermission);
}

class PermissionsError extends PermissionsState {
  final String message;

  PermissionsError(this.message);
}
