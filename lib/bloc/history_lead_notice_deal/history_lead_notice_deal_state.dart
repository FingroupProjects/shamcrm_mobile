import 'package:crm_task_manager/models/lead_history_model.dart';
import 'package:crm_task_manager/models/notice_history_model.dart';
import 'package:crm_task_manager/models/deal_history_model.dart'; // ← Добавь этот импорт
import 'package:equatable/equatable.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class LeadHistoryLoaded extends HistoryState {
  final List<LeadHistory> history;
  const LeadHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class NoticeHistoryLoaded extends HistoryState {
  final List<NoticeHistory> history;
  const NoticeHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class DealHistoryLoaded extends HistoryState {
  final List<DealHistoryLead> history;
  const DealHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}