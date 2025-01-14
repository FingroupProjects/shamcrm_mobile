// States
abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<double> data;
  UserLoaded({required this.data});
}

class UserError extends UserState {
  final String message;
  UserError({required this.message});
}