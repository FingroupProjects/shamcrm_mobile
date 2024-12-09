import 'package:equatable/equatable.dart';

abstract class LeadToCState extends Equatable {
  const LeadToCState();

  @override
  List<Object> get props => [];
}

class LeadToCInitial extends LeadToCState {}

class LeadToCSuccess extends LeadToCState {}


class LeadToCLoading extends LeadToCState {}

class LeadToCLoaded extends LeadToCState {
  final List leadData;

  const LeadToCLoaded(this.leadData);

  @override
  List<Object> get props => [leadData];
}

class LeadToCError extends LeadToCState {
  final String message;

  const LeadToCError(this.message);

  @override
  List<Object> get props => [message];
}