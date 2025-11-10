abstract class UserOverdueTaskEvent {}

class LoadUserOverdueTaskData extends UserOverdueTaskEvent {
  final int id;

  LoadUserOverdueTaskData({required this.id});
}