// bloc/role/role_event.dart
import 'package:equatable/equatable.dart';

abstract class RoleEvent extends Equatable {
  const RoleEvent();

  @override
  List<Object> get props => [];
}

class FetchRoles extends RoleEvent {}