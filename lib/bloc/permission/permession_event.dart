abstract class PermissionsEvent {}

class FetchPermissionsEvent extends PermissionsEvent {

}

class SavePermissionsEvent extends PermissionsEvent {
  final List<String> permissions;

  SavePermissionsEvent(this.permissions);
}

class CheckPermissionEvent extends PermissionsEvent {
  final String permission;

  CheckPermissionEvent(this.permission);
}
