import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';

abstract class MovementState extends Equatable {
  const MovementState();

  @override
  List<Object> get props => [];
}

class MovementInitial extends MovementState {}

class MovementLoading extends MovementState {}

class MovementLoaded extends MovementState {
  final List<IncomingDocument> data;
  final Pagination? pagination;
  final bool hasReachedMax;
  final List<IncomingDocument>? selectedData;

  const MovementLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
    this.selectedData = const [],
  });

  @override
  List<Object> get props => [data, hasReachedMax, selectedData ?? []];
}

class MovementError extends MovementState {
  final String message;
  final int? statusCode;

  const MovementError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class MovementCreateLoading extends MovementState {}

class MovementCreateSuccess extends MovementState {
  final String message;

  const MovementCreateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MovementCreateError extends MovementState {
  final String message;
  final int? statusCode;

  const MovementCreateError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class MovementUpdateLoading extends MovementState {}

class MovementUpdateSuccess extends MovementState {
  final String message;

  const MovementUpdateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MovementUpdateError extends MovementState {
  final String message;
  final int? statusCode;

  const MovementUpdateError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class MovementDeleteLoading extends MovementState {}

class MovementDeleteSuccess extends MovementState {
  final String message;
  final bool shouldReload;

  const MovementDeleteSuccess(this.message, {this.shouldReload = true});

  @override
  List<Object> get props => [message, shouldReload];
}

class MovementDeleteError extends MovementState {
  final String message;
  final int? statusCode;

  const MovementDeleteError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class MovementRestoreLoading extends MovementState {}

class MovementRestoreSuccess extends MovementState {
  final String message;

  const MovementRestoreSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MovementRestoreError extends MovementState {
  final String message;
  final int? statusCode;

  const MovementRestoreError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

// Mass Approve States
class MovementApproveMassLoading extends MovementState {}

class MovementApproveMassSuccess extends MovementState {
  final String message;

  const MovementApproveMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MovementApproveMassError extends MovementState {
  final String message;
  final int? statusCode;

  const MovementApproveMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

// Mass Disapprove States
class MovementDisapproveMassLoading extends MovementState {}

class MovementDisapproveMassSuccess extends MovementState {
  final String message;

  const MovementDisapproveMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MovementDisapproveMassError extends MovementState {
  final String message;
  final int? statusCode;

  const MovementDisapproveMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

// Mass Delete States
class MovementDeleteMassLoading extends MovementState {}

class MovementDeleteMassSuccess extends MovementState {
  final String message;

  const MovementDeleteMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MovementDeleteMassError extends MovementState {
  final String message;
  final int? statusCode;

  const MovementDeleteMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

// Mass Restore States
class MovementRestoreMassLoading extends MovementState {}

class MovementRestoreMassSuccess extends MovementState {
  final String message;

  const MovementRestoreMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MovementRestoreMassError extends MovementState {
  final String message;
  final int? statusCode;

  const MovementRestoreMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}