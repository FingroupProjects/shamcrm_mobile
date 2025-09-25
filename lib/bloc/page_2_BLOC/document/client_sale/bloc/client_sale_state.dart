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
  final int? statusCode;

  const ClientSaleError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class ClientSaleCreateLoading extends ClientSaleState {}

final class ClientSaleCreateSuccess extends ClientSaleState {
  final String message;

  const ClientSaleCreateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class ClientSaleCreateError extends ClientSaleState {
  final String message;
  final int? statusCode;

  const ClientSaleCreateError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class ClientSaleUpdateSuccess extends ClientSaleState {
  final String message;

  const ClientSaleUpdateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class ClientSaleUpdateError extends ClientSaleState {
  final String message;
  final int? statusCode;

  const ClientSaleUpdateError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}