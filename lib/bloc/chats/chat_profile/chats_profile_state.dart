import 'package:crm_task_manager/models/ChatById_model.dart';
import 'package:equatable/equatable.dart';

abstract class ChatProfileState extends Equatable {
  const ChatProfileState();
  
  @override
  List<Object> get props => [];
}

class ChatProfileInitial extends ChatProfileState {}
class ChatProfileLoading extends ChatProfileState {}
class ChatProfileLoaded extends ChatProfileState {
  final ChatProfile profile;

  const ChatProfileLoaded(this.profile);

  @override
  List<Object> get props => [profile];
}
class ChatProfileError extends ChatProfileState {
  final String message;

  const ChatProfileError(this.message);

  @override
  List<Object> get props => [message];
}