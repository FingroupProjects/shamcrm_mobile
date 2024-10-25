// notes_state.dart
import 'package:crm_task_manager/models/notes_model.dart';

abstract class NotesState {}

class NotesInitial extends NotesState {}

class NotesLoading extends NotesState {}

class NotesLoaded extends NotesState {
  final List<Notes> notes;

  NotesLoaded(this.notes);
}

class NotesError extends NotesState {
  final String message;

  NotesError(this.message);
}
