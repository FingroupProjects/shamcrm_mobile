// notifications_state.dart
abstract class DeleteMessageState {}

class DeleteMessageInitial extends DeleteMessageState {}

class DeleteMessageInProgress extends DeleteMessageState {}

class DeleteMessageSuccess extends DeleteMessageState {}

class DeleteMessageError extends DeleteMessageState {
  final String errorMessage;

  DeleteMessageError(this.errorMessage);
}
