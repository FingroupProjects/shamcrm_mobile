abstract class CalendarBlocEvent {
  const CalendarBlocEvent();
}

class FetchCalendarEvents extends CalendarBlocEvent {
  final int month;
  final int year;

  const FetchCalendarEvents(this.month, this.year);
}