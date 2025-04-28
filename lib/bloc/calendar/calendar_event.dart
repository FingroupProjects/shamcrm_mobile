abstract class CalendarBlocEvent {
  const CalendarBlocEvent();
}

class FetchCalendarEvents extends CalendarBlocEvent {
  final int month;
  final int year;
  final String? search;
  final List<String>? types;

  const FetchCalendarEvents(this.month, this.year, {this.search, this.types});
}