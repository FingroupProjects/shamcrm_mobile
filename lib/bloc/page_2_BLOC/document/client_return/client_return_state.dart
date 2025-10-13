part of 'client_return_bloc.dart';

sealed class ClientReturnState extends Equatable {
  const ClientReturnState();

  @override
  List<Object> get props => [];
}

final class ClientReturnInitial extends ClientReturnState {}

final class ClientReturnLoading extends ClientReturnState {}

final class ClientReturnLoaded extends ClientReturnState {
  final List<IncomingDocument> data;
  final Pagination? pagination;
  final bool hasReachedMax;

  const ClientReturnLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
  });

  @override
  List<Object> get props => [data, hasReachedMax];
}

final class ClientReturnError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class ClientReturnCreateLoading extends ClientReturnState {}

final class ClientReturnCreateSuccess extends ClientReturnState {
  final String message;

  const ClientReturnCreateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class ClientReturnCreateError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnCreateError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class ClientReturnUpdateSuccess extends ClientReturnState {
  final String message;

  const ClientReturnUpdateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class ClientReturnUpdateError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnUpdateError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class ClientReturnDeleteLoading extends ClientReturnState {}

class ClientReturnDeleteSuccess extends ClientReturnState {
  final String message;
  final bool shouldReload;

  const ClientReturnDeleteSuccess(this.message, {this.shouldReload = true});

  @override
  List<Object> get props => [message, shouldReload];
}

class ClientReturnDeleteError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnDeleteError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class ClientReturnRestoreLoading extends ClientReturnState {}

class ClientReturnRestoreSuccess extends ClientReturnState {
  final String message;

  const ClientReturnRestoreSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ClientReturnRestoreError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnRestoreError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}