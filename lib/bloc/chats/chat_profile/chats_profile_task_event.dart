import 'package:equatable/equatable.dart';

abstract class TaskProfileEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchTaskProfile extends TaskProfileEvent {
  final int chatId;

  FetchTaskProfile(this.chatId,);

  @override
  List<Object> get props => [chatId];
}
