import 'package:crm_task_manager/models/lead_history_model.dart';
import 'package:equatable/equatable.dart';

abstract class HistoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<LeadHistory> leadHistory;

  HistoryLoaded(this.leadHistory);

  @override
  List<Object?> get props => [leadHistory];
}

class HistoryError extends HistoryState {
  final String message;

  HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
