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
  final List<IncomingDocument>? selectedData;

  const ClientReturnLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
    this.selectedData = const [],
  });

  @override
  List<Object> get props => [data, hasReachedMax, selectedData ?? []];
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

final class ClientReturnUpdateLoading extends ClientReturnState {}

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

final class ClientReturnDeleteLoading extends ClientReturnState {}

final class ClientReturnDeleteSuccess extends ClientReturnState {
  final String message;
  final bool shouldReload;

  const ClientReturnDeleteSuccess(this.message, {this.shouldReload = true});

  @override
  List<Object> get props => [message, shouldReload];
}

final class ClientReturnDeleteError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnDeleteError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class ClientReturnRestoreLoading extends ClientReturnState {}

final class ClientReturnRestoreSuccess extends ClientReturnState {
  final String message;

  const ClientReturnRestoreSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class ClientReturnRestoreError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnRestoreError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

// Mass Operation States
final class ClientReturnApproveMassLoading extends ClientReturnState {}

final class ClientReturnApproveMassSuccess extends ClientReturnState {
  final String message;

  const ClientReturnApproveMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class ClientReturnApproveMassError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnApproveMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class ClientReturnDisapproveMassLoading extends ClientReturnState {}

final class ClientReturnDisapproveMassSuccess extends ClientReturnState {
  final String message;

  const ClientReturnDisapproveMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class ClientReturnDisapproveMassError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnDisapproveMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class ClientReturnDeleteMassLoading extends ClientReturnState {}

final class ClientReturnDeleteMassSuccess extends ClientReturnState {
  final String message;

  const ClientReturnDeleteMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class ClientReturnDeleteMassError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnDeleteMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class ClientReturnRestoreMassLoading extends ClientReturnState {}

final class ClientReturnRestoreMassSuccess extends ClientReturnState {
  final String message;

  const ClientReturnRestoreMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class ClientReturnRestoreMassError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnRestoreMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}