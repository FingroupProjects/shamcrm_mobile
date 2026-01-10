part of 'client_sale_bloc.dart';

sealed class ClientSaleState extends Equatable {
  const ClientSaleState();

  @override
  List<Object> get props => [];
}

final class ClientSaleInitial extends ClientSaleState {}

final class ClientSaleLoading extends ClientSaleState {}

final class ClientSaleLoaded extends ClientSaleState {
  final List<IncomingDocument> data;
  final Pagination? pagination;
  final bool hasReachedMax;
  final List<IncomingDocument>? selectedData;

  const ClientSaleLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
    this.selectedData = const [],
  });

  @override
  List<Object> get props => [data, hasReachedMax, selectedData ?? []];
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

final class ClientSaleDeleteLoading extends ClientSaleState {}

final class ClientSaleDeleteSuccess extends ClientSaleState {
  final String message;
  final bool shouldReload;

  const ClientSaleDeleteSuccess(this.message, {this.shouldReload = true});

  @override
  List<Object> get props => [message];
}

final class ClientSaleDeleteError extends ClientSaleState {
  final String message;
  final int? statusCode;

  const ClientSaleDeleteError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class ClientSaleRestoreLoading extends ClientSaleState {}

final class ClientSaleRestoreSuccess extends ClientSaleState {
  final String message;

  const ClientSaleRestoreSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class ClientSaleRestoreError extends ClientSaleState {
  final String message;
  final int? statusCode;

  const ClientSaleRestoreError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class ClientSaleApproveMassLoading extends ClientSaleState {}

final class ClientSaleApproveMassSuccess extends ClientSaleState {
  final String message;

  const ClientSaleApproveMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class ClientSaleApproveMassError extends ClientSaleState {
  final String message;
  final int? statusCode;

  const ClientSaleApproveMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class ClientSaleDisapproveMassLoading extends ClientSaleState {}

final class ClientSaleDisapproveMassSuccess extends ClientSaleState {
  final String message;

  const ClientSaleDisapproveMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class ClientSaleDisapproveMassError extends ClientSaleState {
  final String message;
  final int? statusCode;

  const ClientSaleDisapproveMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class ClientSaleDeleteMassLoading extends ClientSaleState {}

final class ClientSaleDeleteMassSuccess extends ClientSaleState {
  final String message;

  const ClientSaleDeleteMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class ClientSaleDeleteMassError extends ClientSaleState {
  final String message;
  final int? statusCode;

  const ClientSaleDeleteMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class ClientSaleRestoreMassLoading extends ClientSaleState {}

final class ClientSaleRestoreMassSuccess extends ClientSaleState {
  final String message;

  const ClientSaleRestoreMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class ClientSaleRestoreMassError extends ClientSaleState {
  final String message;
  final int? statusCode;

  const ClientSaleRestoreMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}
