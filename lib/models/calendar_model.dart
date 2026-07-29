class CalendarEvent {
  final int id;
  final String name;
  final DateTime date;
  final String type;
  final bool isFinished;

  CalendarEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.isFinished,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as int,
      // The API can return a calendar item without a title. One malformed
      // item must not prevent the complete month from being rendered.
      name: json['name']?.toString() ?? 'Без названия',
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      isFinished: json['is_finished'] as bool,
    );
  }
}
