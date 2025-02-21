import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class FetchLeadHistory extends HistoryEvent {
  final int leadId;
  const FetchLeadHistory(this.leadId);

  @override
  List<Object?> get props => [leadId];
}

class FetchNoticeHistory extends HistoryEvent {
  final int leadId;
  const FetchNoticeHistory(this.leadId);

  @override
  List<Object?> get props => [leadId];
}

class FetchDealHistory extends HistoryEvent {
  final int leadId;
  const FetchDealHistory(this.leadId);

  @override
  List<Object?> get props => [leadId];
}