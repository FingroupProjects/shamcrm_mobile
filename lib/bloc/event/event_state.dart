// event_state.dart
import 'package:crm_task_manager/models/event/event_model.dart';

abstract class EventState {}

class EventInitial extends EventState {}

class EventLoading extends EventState {
  final bool isFirstFetch;
  
  EventLoading({this.isFirstFetch = true});
}

class EventDataLoaded extends EventState {
  final List<NoticeEvent> events;
  final int currentPage;
  final bool hasReachedEnd;
  final Map<int, int> eventCounts;
  /// Сколько событий в текущем интервале, не только на этой странице.
  final int total;
  /// past | today | tomorrow | upcoming
  final String dateType;
  /// Числа на всех вкладках. Ключ — date_type.
  final Map<String, int> dateTotals;

  EventDataLoaded({
    required this.events,
    required this.currentPage,
    required this.hasReachedEnd,
    this.eventCounts = const {},
    this.total = 0,
    this.dateType = EventDateType.today,
    this.dateTotals = const {},
  });

  EventDataLoaded copyWith({
    List<NoticeEvent>? events,
    int? currentPage,
    bool? hasReachedEnd,
    Map<int, int>? eventCounts,
    int? total,
    String? dateType,
    Map<String, int>? dateTotals,
  }) {
    return EventDataLoaded(
      events: events ?? this.events,
      currentPage: currentPage ?? this.currentPage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      eventCounts: eventCounts ?? this.eventCounts,
      total: total ?? this.total,
      dateType: dateType ?? this.dateType,
      dateTotals: dateTotals ?? this.dateTotals,
    );
  }
}

class EventSuccess extends EventState {
  final String message;

  EventSuccess(this.message);
}
class EventError extends EventState {
  final String message;
  EventError(this.message);
}
class EventUpdateLoading extends EventState {}

class EventUpdateSuccess extends EventState {
  final String message;
  EventUpdateSuccess(this.message);
}
class EventDeleted extends EventState {
  final String message;

  EventDeleted(this.message);
}
class EventUpdateError extends EventState {
  final String message;
  EventUpdateError(this.message);
}
class EventFinished extends EventState {
  final String message;

  EventFinished(this.message);
}

