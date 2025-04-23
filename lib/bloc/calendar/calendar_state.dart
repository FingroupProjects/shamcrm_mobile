import 'package:crm_task_manager/models/calendar_model.dart';
import 'package:equatable/equatable.dart';

abstract class CalendarBlocState extends Equatable {
  const CalendarBlocState();

  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarBlocState {}

class CalendarLoading extends CalendarBlocState {}

class CalendarLoaded extends CalendarBlocState {
  final List<CalendarEvent> events;
  final DateTime selectedDate;

  const CalendarLoaded(this.events, this.selectedDate);

  @override
  List<Object?> get props => [events, selectedDate];
}

class CalendarError extends CalendarBlocState {
  final String message;

  const CalendarError(this.message);

  @override
  List<Object?> get props => [message];
}