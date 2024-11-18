import 'package:crm_task_manager/models/leadById_model.dart';

abstract class LeadByIdState {}

class LeadByIdInitial extends LeadByIdState {}

class LeadByIdLoading extends LeadByIdState {}

class LeadByIdLoaded extends LeadByIdState {
  final LeadById lead;
  LeadByIdLoaded(this.lead);
}

class LeadByIdError extends LeadByIdState {
  final String message;
  LeadByIdError(this.message);
}
