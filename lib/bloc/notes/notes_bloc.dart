import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'notes_event.dart';
import 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final ApiService apiService;

  NotesBloc(this.apiService) : super(NotesInitial()) {
    on<FetchNotes>((event, emit) async {
      emit(NotesLoading());
      try {
        final notes = await apiService.getLeadNotes(event.leadId);
        emit(NotesLoaded(notes));
      } catch (e) {
        emit(NotesError('Ошибка загрузки заметок'));
      }
    });

    on<CreateNotes>(_createNotes);
    on<UpdateNotes>(_updateNotes);
  }

  Future<void> _createNotes(CreateNotes event, Emitter<NotesState> emit) async {
  emit(NotesLoading());
  try {
    final result = await apiService.createNotes(
      body: event.body,
      leadId: event.leadId,
      date: event.date,
      sendNotification: event.sendNotification,
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
      body: event.body,
      date: event.date,
      sendNotification: event.sendNotification,
    );

    if (result['success']) {
      emit(NotesSuccess('Заметка обновлена успешно'));
      add(FetchNotes(event.leadId));
    } else {
      emit(NotesError(result['message']));
    }
  } catch (e) {
    print("Error during update: ${e.toString()}");
    emit(NotesError('Ошибка обновления заметки: ${e.toString()}'));
  }
}

}
