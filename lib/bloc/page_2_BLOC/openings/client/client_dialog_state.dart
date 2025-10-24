import '../../../../models/page_2/openings/client_openings_model.dart';

abstract class ClientDialogState {}

class ClientDialogInitial extends ClientDialogState {}

class ClientDialogLoading extends ClientDialogState {}

class ClientDialogLoaded extends ClientDialogState {
  final List<ClientOpening> leads;

  ClientDialogLoaded({required this.leads});
}

class ClientDialogError extends ClientDialogState {
  final String message;

  ClientDialogError({required this.message});
}

