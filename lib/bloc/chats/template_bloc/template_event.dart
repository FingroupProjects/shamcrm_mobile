abstract class TemplateEvent {}

class FetchTemplates extends TemplateEvent {}

class FilterTemplates extends TemplateEvent {
  final String query;

  FilterTemplates(this.query);
}