import 'package:crm_task_manager/models/template_model.dart';


abstract class TemplateState {}

class TemplateInitial extends TemplateState {}

class TemplateLoading extends TemplateState {}

class TemplateLoaded extends TemplateState {
  final List<Template> templates;
  final List<Template> filteredTemplates;

  TemplateLoaded({
    required this.templates,
    this.filteredTemplates = const [],
  });
}

class TemplateError extends TemplateState {
  final String message;

  TemplateError(this.message);
}