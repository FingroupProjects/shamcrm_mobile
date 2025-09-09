part of 'client_sale_bloc.dart';

sealed class ClientSaleState extends Equatable {
  const ClientSaleState();

  @override
  List<Object> get props => [];
}

final class ClientSaleInitial extends ClientSaleState {}

final class ClientSaleLoading extends ClientSaleState {}

final class ClientSaleLoaded extends ClientSaleState {
  final List<IncomingDocument> data; // Единый список документов
  final Pagination? pagination;
  final bool hasReachedMax;

  const ClientSaleLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
  });

  @override
  List<Object> get props => [data, hasReachedMax];
}

final class ClientSaleError extends ClientSaleState {
  final String message;

  const ClientSaleError(this.message);

  @override
  List<Object> get props => [message];
}
