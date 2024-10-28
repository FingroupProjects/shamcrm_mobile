abstract class NotesEvent {}

class FetchNotes extends NotesEvent {
  final int leadId;

  FetchNotes(this.leadId);
}

class CreateNotes extends NotesEvent {
  final String body;
  final int leadId;
  final DateTime? date;
  final bool sendNotification;

  CreateNotes({
    required this.body,
    required this.leadId,
    this.date,
    this.sendNotification = false,
  });
}

class UpdateNotes extends NotesEvent {
  final int noteId;
  final int leadId;
  final String body;
  final DateTime? date;
  final bool sendNotification;

  UpdateNotes({
    required this.noteId,
    required this.leadId,
    required this.body,
    this.date,
    this.sendNotification = false,
  });
}

class DeleteNote extends NotesEvent {
  final int noteId;
  final int leadId; // Include leadId to fetch notes after deletion

  DeleteNote(this.noteId, this.leadId);
}

