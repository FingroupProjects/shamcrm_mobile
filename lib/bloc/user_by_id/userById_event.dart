abstract class UserByIdEvent {}

class FetchUserByIdEvent extends UserByIdEvent {
  final int userId;
  FetchUserByIdEvent({required this.userId});
}