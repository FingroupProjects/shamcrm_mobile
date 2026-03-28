import 'package:crm_task_manager/models/LeadStatusForFilter.dart';

abstract class LeadStatusForFilterState {}

class LeadStatusForFilterInitial extends LeadStatusForFilterState {}

class LeadStatusForFilterLoading extends LeadStatusForFilterState {}

class LeadStatusForFilterLoaded extends LeadStatusForFilterState {
  final List<LeadStatusForFilter> leadStatusForFilter;

  LeadStatusForFilterLoaded(this.leadStatusForFilter);
}

class LeadStatusForFilterError extends LeadStatusForFilterState {
  final String message;

  LeadStatusForFilterError(this.message);
}