import 'package:equatable/equatable.dart';

abstract class LeadToCEvent extends Equatable {
  const LeadToCEvent();

  @override
  List<Object> get props => [];
}

class FetchLeadToC extends LeadToCEvent {
  final int leadId;

  const FetchLeadToC(this.leadId);

  @override
  List<Object> get props => [leadId];
}