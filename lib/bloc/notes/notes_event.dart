// notes_event.dart
abstract class NotesEvent {}

class FetchNotes extends NotesEvent {
  final int leadId;

  FetchNotes(this.leadId);
}
class CreateNotes extends NotesEvent {
  final String body;
  final int leadId;
  final DateTime? date;

  CreateNotes({
    required this.body,
    required this.leadId,
    this.date,
  });
}
