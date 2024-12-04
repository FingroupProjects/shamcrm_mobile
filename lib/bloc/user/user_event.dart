import 'package:equatable/equatable.dart';

abstract class UserTaskEvent extends Equatable {
  const UserTaskEvent();

  @override
  List<Object> get props => [];
}

class FetchUsers extends UserTaskEvent {}
// // bloc/user/user_event.dart
// import 'package:equatable/equatable.dart';

// abstract class UserEvent extends Equatable {
//   const UserEvent();

//   @override
//   List<Object> get props => [];
// }

// class FetchUsers extends UserEvent {}