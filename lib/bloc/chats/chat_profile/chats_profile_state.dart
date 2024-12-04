import 'package:crm_task_manager/models/chatById_model.dart';
import 'package:equatable/equatable.dart';

abstract class ChatProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatProfileInitial extends ChatProfileState {}

class ChatProfileLoading extends ChatProfileState {}

class ChatProfileLoaded extends ChatProfileState {
  final ChatProfile profile;

  ChatProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ChatProfileError extends ChatProfileState {
  final String error;

  ChatProfileError(this.error);

  @override
  List<Object?> get props => [error];
}
