// event_state.dart
import 'package:crm_task_manager/models/event_model.dart';

abstract class EventState {}

class EventInitial extends EventState {}

class EventLoading extends EventState {}

class EventLoaded extends EventState {
  final List<NoticeEvent> events;
  EventLoaded(this.events);
}

class EventError extends EventState {
  final String message;
  EventError(this.message);
}