abstract class PermissionsEvent {}

class FetchPermissionsEvent extends PermissionsEvent {
  final String roleId;

  FetchPermissionsEvent(this.roleId);
}

class SavePermissionsEvent extends PermissionsEvent {
  final List<String> permissions;

  SavePermissionsEvent(this.permissions);
}

class CheckPermissionEvent extends PermissionsEvent {
  final String permission;

  CheckPermissionEvent(this.permission);
}
