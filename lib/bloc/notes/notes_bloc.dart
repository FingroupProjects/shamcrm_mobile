// notes_bloc.dart
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
  }

  Future<void> _createNotes(CreateNotes event, Emitter<NotesState> emit) async {
    emit(NotesLoading());
    try {
      final result = await apiService.createNotes(
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
}
