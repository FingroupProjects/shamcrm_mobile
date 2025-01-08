// notifications_event.dart
abstract class DeleteMessageEvent {}

class DeleteMessage extends DeleteMessageEvent {
  final int messageId;

  DeleteMessage(this.messageId);
}
