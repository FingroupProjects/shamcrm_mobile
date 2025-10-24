import '../../../../models/page_2/openings/client_openings_model.dart';

abstract class ClientOpeningsState {}

class ClientOpeningsInitial extends ClientOpeningsState {}

class ClientOpeningsLoading extends ClientOpeningsState {}

class ClientOpeningsLoaded extends ClientOpeningsState {
  final List<ClientOpening> clients;
  final bool hasReachedMax;
  final Pagination pagination;

  ClientOpeningsLoaded({
    required this.clients,
    required this.hasReachedMax,
    required this.pagination,
  });

  ClientOpeningsLoaded copyWith({
    List<ClientOpening>? clients,
    bool? hasReachedMax,
    Pagination? pagination,
  }) {
    return ClientOpeningsLoaded(
      clients: clients ?? this.clients,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      pagination: pagination ?? this.pagination,
    );
  }
}

class ClientOpeningsError extends ClientOpeningsState {
  final String message;

  ClientOpeningsError({required this.message});
}

class ClientOpeningsPaginationError extends ClientOpeningsState {
  final String message;

  ClientOpeningsPaginationError({required this.message});
}

class Pagination {
  final int total;
  final int count;
  final int per_page;
  final int current_page;
  final int total_pages;

  Pagination({
    required this.total,
    required this.count,
    required this.per_page,
    required this.current_page,
    required this.total_pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] as int,
      count: json['count'] as int,
      per_page: json['per_page'] as int,
      current_page: json['current_page'] as int,
      total_pages: json['total_pages'] as int,
    );
  }
}
