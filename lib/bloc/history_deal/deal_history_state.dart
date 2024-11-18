import 'package:crm_task_manager/models/deal_history_model.dart';
import 'package:equatable/equatable.dart';

abstract class DealHistoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DealHistoryInitial extends DealHistoryState {}

class DealHistoryLoading extends DealHistoryState {}

class DealHistoryLoaded extends DealHistoryState {
  final List<DealHistory> dealHistory;

  DealHistoryLoaded(this.dealHistory);

  @override
  List<Object?> get props => [dealHistory];
}

class DealHistoryError extends DealHistoryState {
  final String message;

  DealHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
