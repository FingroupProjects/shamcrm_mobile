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
        emit(NotesError('Error loading notes'));
      }
    });
  }
}
