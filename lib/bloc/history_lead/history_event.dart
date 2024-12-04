import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchLeadHistory extends HistoryEvent {
  final int leadId;

  FetchLeadHistory(this.leadId);

  @override
  List<Object?> get props => [leadId];
}
