part of 'write_off_bloc.dart';

sealed class WriteOffState extends Equatable {
  const WriteOffState();

  @override
  List<Object> get props => [];
}

final class WriteOffInitial extends WriteOffState {}

final class WriteOffLoading extends WriteOffState {}

final class WriteOffLoaded extends WriteOffState {
  final List<IncomingDocument> data;
  final Pagination? pagination;
  final bool hasReachedMax;
  final List<IncomingDocument>? selectedData;

  const WriteOffLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
    this.selectedData = const [],
  });

  @override
  List<Object> get props => [data, hasReachedMax, selectedData ?? []];
}

final class WriteOffError extends WriteOffState {
  final String message;
  final int? statusCode;

  const WriteOffError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class WriteOffCreateLoading extends WriteOffState {}

final class WriteOffCreateSuccess extends WriteOffState {
  final String message;

  const WriteOffCreateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class WriteOffCreateError extends WriteOffState {
  final String message;
  final int? statusCode;

  const WriteOffCreateError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class WriteOffUpdateLoading extends WriteOffState {}

final class WriteOffUpdateSuccess extends WriteOffState {
  final String message;

  const WriteOffUpdateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class WriteOffUpdateError extends WriteOffState {
  final String message;
  final int? statusCode;

  const WriteOffUpdateError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class WriteOffDeleteLoading extends WriteOffState {}

final class WriteOffDeleteSuccess extends WriteOffState {
  final String message;
  final bool shouldReload;

  const WriteOffDeleteSuccess(this.message, {this.shouldReload = true});

  @override
  List<Object> get props => [message, shouldReload];
}

final class WriteOffDeleteError extends WriteOffState {
  final String message;
  final int? statusCode;

  const WriteOffDeleteError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class WriteOffRestoreLoading extends WriteOffState {}

final class WriteOffRestoreSuccess extends WriteOffState {
  final String message;

  const WriteOffRestoreSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class WriteOffRestoreError extends WriteOffState {
  final String message;
  final int? statusCode;

  const WriteOffRestoreError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

// Mass Operation States
final class WriteOffApproveMassLoading extends WriteOffState {}

final class WriteOffApproveMassSuccess extends WriteOffState {
  final String message;

  const WriteOffApproveMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class WriteOffApproveMassError extends WriteOffState {
  final String message;
  final int? statusCode;

  const WriteOffApproveMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class WriteOffDisapproveMassLoading extends WriteOffState {}

final class WriteOffDisapproveMassSuccess extends WriteOffState {
  final String message;

  const WriteOffDisapproveMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class WriteOffDisapproveMassError extends WriteOffState {
  final String message;
  final int? statusCode;

  const WriteOffDisapproveMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class WriteOffDeleteMassLoading extends WriteOffState {}

final class WriteOffDeleteMassSuccess extends WriteOffState {
  final String message;

  const WriteOffDeleteMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class WriteOffDeleteMassError extends WriteOffState {
  final String message;
  final int? statusCode;

  const WriteOffDeleteMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

final class WriteOffRestoreMassLoading extends WriteOffState {}

final class WriteOffRestoreMassSuccess extends WriteOffState {
  final String message;

  const WriteOffRestoreMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class WriteOffRestoreMassError extends WriteOffState {
  final String message;
  final int? statusCode;

  const WriteOffRestoreMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}