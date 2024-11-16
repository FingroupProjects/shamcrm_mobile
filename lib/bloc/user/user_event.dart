import 'package:equatable/equatable.dart';

abstract class UserTaskEvent extends Equatable {
  const UserTaskEvent();

  @override
  List<Object> get props => [];
}

class FetchUsers extends UserTaskEvent {}
