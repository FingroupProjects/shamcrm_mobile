
import 'package:crm_task_manager/models/user_byId_model..dart';

abstract class UserByIdState {}

class UserByIdInitial extends UserByIdState {}

class UserByIdLoading extends UserByIdState {}

class UserByIdLoaded extends UserByIdState {
  final UserByIdProfile user;
  UserByIdLoaded(this.user);
}

class UserByIdError extends UserByIdState {
  final String message;
  UserByIdError(this.message);
}