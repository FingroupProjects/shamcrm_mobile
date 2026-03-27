import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'template_event.dart';
import 'template_state.dart';

class TemplateBloc extends Bloc<TemplateEvent, TemplateState> {
  final ApiService apiService;

  TemplateBloc(this.apiService) : super(TemplateInitial()) {
    on<FetchTemplates>(_onFetchTemplates);
    on<FilterTemplates>(_onFilterTemplates);
  }

  Future<void> _onFetchTemplates(FetchTemplates event, Emitter<TemplateState> emit) async {
    emit(TemplateLoading());
    try {
      final response = await apiService.getTemplates();
      emit(TemplateLoaded(templates: response.templates));
    } catch (e) {
      emit(TemplateError(e.toString()));
    }
  }

  void _onFilterTemplates(FilterTemplates event, Emitter<TemplateState> emit) {
    if (state is TemplateLoaded) {
      final loadedState = state as TemplateLoaded;
      final filtered = loadedState.templates
          .where((template) => template.title.toLowerCase().contains(event.query.toLowerCase()))
          .toList();
      emit(TemplateLoaded(
        templates: loadedState.templates,
        filteredTemplates: filtered,
      ));
    }
  }
}