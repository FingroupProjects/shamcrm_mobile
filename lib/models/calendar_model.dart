import 'package:crm_task_manager/utils/safe_converters.dart';

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
      id: SafeConverters.toInt(json['id']),
      name: SafeConverters.toSafeString(json['name']),
      date: SafeConverters.toDateTime(json['date']),
      type: SafeConverters.toSafeString(json['type']),
      isFinished: SafeConverters.toBool(json['is_finished']),
    );
  }
}
