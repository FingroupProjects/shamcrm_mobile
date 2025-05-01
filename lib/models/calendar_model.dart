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
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      isFinished: json['is_finished'] as bool,
    );
  }
}