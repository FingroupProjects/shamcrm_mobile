import 'package:crm_task_manager/models/notes_model.dart';

abstract class NotesState {}

class NotesInitial extends NotesState {}

class NotesLoading extends NotesState {}

class NotesLoaded extends NotesState {
  final List<Notes> notes;
  final int currentPage;

  NotesLoaded(this.notes, {this.currentPage = 1});

  NotesLoaded merge(List<Notes> newNotes) {
    return NotesLoaded([...notes, ...newNotes], currentPage: currentPage + 1);
  }
}

class NotesError extends NotesState {
  final String message;

  NotesError(this.message);
}

class NotesSuccess extends NotesState {
  final String message;

  NotesSuccess(this.message);
}

class NotesDeleted extends NotesState {
  final String message;

  NotesDeleted(this.message);
}
