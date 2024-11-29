import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'notes_event.dart';
import 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final ApiService apiService;
  bool allNotesFetched = false; 

  NotesBloc(this.apiService) : super(NotesInitial()) {
    on<FetchNotes>(_fetchNotes); 
    on<FetchMoreNotes>(_fetchMoreNotes);
    on<CreateNotes>(_createNotes);
    on<UpdateNotes>(_updateNotes);
    on<DeleteNote>(_deleteNote);
  }

  Future<void> _fetchNotes(FetchNotes event, Emitter<NotesState> emit) async {
    emit(NotesLoading());

    try {
      final notes = await apiService.getLeadNotes(event.leadId);
      allNotesFetched = notes.isEmpty; 
      emit(NotesLoaded(notes,
          currentPage: 1)); 
    } catch (e) {
      emit(NotesError('Не удалось загрузить заметки: ${e.toString()}'));
    }
  }

  Future<void> _fetchMoreNotes(
      FetchMoreNotes event, Emitter<NotesState> emit) async {
    if (allNotesFetched)
      return; 

    try {
      final notes = await apiService.getLeadNotes(event.leadId,
          page: event.currentPage + 1);
      if (notes.isEmpty) {
        allNotesFetched = true; 
        return; 
      }
      if (state is NotesLoaded) {
        final currentState = state as NotesLoaded;
        emit(currentState.merge(notes));
      }
    } catch (e) {
      emit(NotesError(
          'Не удалось загрузить дополнительные заметки: ${e.toString()}'));
    }
  }

  Future<void> _createNotes(CreateNotes event, Emitter<NotesState> emit) async {
    emit(NotesLoading());

    try {
      final result = await apiService.createNotes(
        title: event.title,
        body: event.body,
        leadId: event.leadId,
        date: event.date,
      );

      if (result['success']) {
        emit(NotesSuccess('Заметка создана успешно'));
        add(FetchNotes(event.leadId));
      } else {
        emit(NotesError(result['message']));
      }
    } catch (e) {
      emit(NotesError('Ошибка создания заметки: ${e.toString()}'));
    }
  }

  Future<void> _updateNotes(UpdateNotes event, Emitter<NotesState> emit) async {
    emit(NotesLoading());

    try {
      final result = await apiService.updateNotes(
        noteId: event.noteId,
        leadId: event.leadId,
        title: event.title,
        body: event.body,
        date: event.date,
      );

      if (result['success']) {
        emit(NotesSuccess('Заметка обновлена успешно'));
        add(FetchNotes(event.leadId)); // Перезагрузка заметок после обновления
      } else {
        emit(NotesError(result['message']));
      }
    } catch (e) {
      emit(NotesError('Ошибка обновления заметки: ${e.toString()}'));
    }
  }

  Future<void> _deleteNote(DeleteNote event, Emitter<NotesState> emit) async {
    emit(NotesLoading());

    try {
      final response = await apiService.deleteNotes(event.noteId);
      if (response['result'] == 'Success') {
        emit(NotesDeleted('Заметка удалена успешно'));
        add(FetchNotes(event.leadId)); // Перезагрузка заметок после удаления
      } else {
        emit(NotesError('Ошибка удаления заметки'));
      }
    } catch (e) {
      emit(NotesError('Ошибка удаления заметки: ${e.toString()}'));
    }
  }
}
