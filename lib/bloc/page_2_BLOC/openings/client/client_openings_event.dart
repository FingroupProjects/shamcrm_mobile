abstract class ClientOpeningsEvent {}

class LoadClientOpenings extends ClientOpeningsEvent {

  LoadClientOpenings();
}

class RefreshClientOpenings extends ClientOpeningsEvent {
  RefreshClientOpenings();
}

class DeleteClientOpening extends ClientOpeningsEvent {
  final int id;

  DeleteClientOpening({required this.id});
}

class CreateClientOpening extends ClientOpeningsEvent {
  final int leadId;
  final double ourDuty;
  final double debtToUs;

  CreateClientOpening({
    required this.leadId,
    required this.ourDuty,
    required this.debtToUs,
  });
}

class UpdateClientOpening extends ClientOpeningsEvent {
  final int id;
  final int leadId;
  final double ourDuty;
  final double debtToUs;

  UpdateClientOpening({
    required this.id,
    required this.leadId,
    required this.ourDuty,
    required this.debtToUs,
  });
}

class LoadClientOpeningsLeads extends ClientOpeningsEvent {}

class RefreshClientOpeningsLeads extends ClientOpeningsEvent {}
