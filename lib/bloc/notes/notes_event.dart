abstract class NotesEvent {}

class FetchNotes extends NotesEvent {
  final int leadId;

  FetchNotes(this.leadId);
}

class FetchMoreNotes extends NotesEvent {
  final int leadId;
  final int currentPage;

  FetchMoreNotes(this.leadId, this.currentPage);
}

class CreateNotes extends NotesEvent {
  final String title;
  final String body;
  final int leadId;
  final DateTime? date;
  final List<int> users;
  final List<String>? filePaths; // Новое поле для файлов

  CreateNotes({
    required this.title,
    required this.body,
    required this.leadId,
    this.date,
    required this.users,
    this.filePaths, // Добавляем в конструктор
  });
}

class UpdateNotes extends NotesEvent {
  final int noteId;
  final int leadId;
  final String title;
  final String body;
  final DateTime? date;

  UpdateNotes({
    required this.noteId,
    required this.leadId,
    required this.title,
    required this.body,
    this.date,
  });
}

class DeleteNote extends NotesEvent {
  final int noteId;
  final int leadId;

  DeleteNote(this.noteId, this.leadId);
}
