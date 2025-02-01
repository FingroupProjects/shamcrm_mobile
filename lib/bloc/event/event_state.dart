// event_state.dart
import 'package:crm_task_manager/models/event_model.dart';

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

  EventDataLoaded({
    required this.events,
    required this.currentPage,
    required this.hasReachedEnd,
  });

  EventDataLoaded copyWith({
    List<NoticeEvent>? events,
    int? currentPage,
    bool? hasReachedEnd,
  }) {
    return EventDataLoaded(
      events: events ?? this.events,
      currentPage: currentPage ?? this.currentPage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
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

