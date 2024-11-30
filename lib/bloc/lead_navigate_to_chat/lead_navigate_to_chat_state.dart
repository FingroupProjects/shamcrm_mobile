
import 'package:crm_task_manager/models/lead_navigate_to_chat.dart';

abstract class LeadToChatState {}

class LeadToChatInitial extends LeadToChatState {}

class LeadToChatLoading extends LeadToChatState {}

class LeadToChatLoaded extends LeadToChatState {
  final List<LeadNavigateChat> leadtochat; 

  LeadToChatLoaded(this.leadtochat);
}

class LeadToChatError extends LeadToChatState {
  final String message;

  LeadToChatError(this.message);
}

class LeadToChatSuccess extends LeadToChatState {
  final String message;

  LeadToChatSuccess(this.message);
}

class LeadToChatDeleted extends LeadToChatState {
  final String message;

  LeadToChatDeleted(this.message);
}
