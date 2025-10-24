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
