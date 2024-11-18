import 'package:equatable/equatable.dart';

abstract class DealHistoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchDealHistory extends DealHistoryEvent {
  final int dealId;

  FetchDealHistory(this.dealId);

  @override
  List<Object?> get props => [dealId];
}
