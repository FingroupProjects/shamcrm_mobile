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
  final int currentPage;

  LeadDataLoaded(this.leads, {this.currentPage = 1});

  // Метод для объединения с новыми лидами
  LeadDataLoaded merge(List<Lead> newLeads) {
    return LeadDataLoaded([...leads, ...newLeads],
        currentPage: currentPage + 1);
  }
}

class LeadError extends LeadState {
  final String message;

  LeadError(this.message);
}

class LeadSuccess extends LeadState {
  final String message;

  LeadSuccess(this.message);
}


class LeadDeleted extends LeadState {
  final String message;

  LeadDeleted(this.message);
}

class LeadStatusDeleted extends LeadState {
  final String message;

  LeadStatusDeleted(this.message);
}

