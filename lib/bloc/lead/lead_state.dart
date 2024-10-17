import 'package:crm_task_manager/models/lead_model.dart'; // Модель для Lead

abstract class LeadState {}

class LeadInitial extends LeadState {}

class LeadLoading extends LeadState {}

class LeadLoaded extends LeadState {
  final List<LeadStatus> leadStatuses;

  LeadLoaded(this.leadStatuses);
}

class LeadDataLoaded extends LeadState {
  final List<Lead> leads;

  LeadDataLoaded(this.leads);
}

class LeadError extends LeadState {
  final String message;

  LeadError(this.message);
}

class LeadSuccess extends LeadState {
  final String message;

  LeadSuccess(this.message);
}
