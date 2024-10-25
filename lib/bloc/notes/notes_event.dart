// notes_event.dart
abstract class NotesEvent {}

class FetchNotes extends NotesEvent {
  final int leadId;

  FetchNotes(this.leadId);
}
