abstract class ClientOpeningsEvent {}

class LoadClientOpenings extends ClientOpeningsEvent {
  final int page;
  final String? search;
  final Map<String, dynamic>? filter;

  LoadClientOpenings({
    this.page = 1,
    this.search,
    this.filter,
  });
}

class RefreshClientOpenings extends ClientOpeningsEvent {
  final String? search;
  final Map<String, dynamic>? filter;

  RefreshClientOpenings({
    this.search,
    this.filter,
  });
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

class LoadClientOpeningsLeads extends ClientOpeningsEvent {}

class RefreshClientOpeningsLeads extends ClientOpeningsEvent {}
