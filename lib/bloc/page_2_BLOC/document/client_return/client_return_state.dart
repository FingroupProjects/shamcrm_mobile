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

// Массовое одобрение
class ClientReturnApproveMassLoading extends ClientReturnState {}

class ClientReturnApproveMassSuccess extends ClientReturnState {
  final String message;

  const ClientReturnApproveMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ClientReturnApproveMassError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnApproveMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

// Массовая отмена одобрения
class ClientReturnDisapproveMassLoading extends ClientReturnState {}

class ClientReturnDisapproveMassSuccess extends ClientReturnState {
  final String message;

  const ClientReturnDisapproveMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ClientReturnDisapproveMassError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnDisapproveMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

// Массовое удаление
class ClientReturnDeleteMassLoading extends ClientReturnState {}

class ClientReturnDeleteMassSuccess extends ClientReturnState {
  final String message;

  const ClientReturnDeleteMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ClientReturnDeleteMassError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnDeleteMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

// Массовое восстановление
class ClientReturnRestoreMassLoading extends ClientReturnState {}

class ClientReturnRestoreMassSuccess extends ClientReturnState {
  final String message;

  const ClientReturnRestoreMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ClientReturnRestoreMassError extends ClientReturnState {
  final String message;
  final int? statusCode;

  const ClientReturnRestoreMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}