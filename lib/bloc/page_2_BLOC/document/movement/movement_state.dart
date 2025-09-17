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

  const MovementLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
  });

  @override
  List<Object> get props => [data, hasReachedMax];
}

class MovementError extends MovementState {
  final String message;

  const MovementError(this.message);

  @override
  List<Object> get props => [message];
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

  const MovementCreateError(this.message);

  @override
  List<Object> get props => [message];
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

  const MovementUpdateError(this.message);

  @override
  List<Object> get props => [message];
}

class MovementDeleteLoading extends MovementState {}

class MovementDeleteSuccess extends MovementState {
  final String message;

  const MovementDeleteSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MovementDeleteError extends MovementState {
  final String message;

  const MovementDeleteError(this.message);

  @override
  List<Object> get props => [message];
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

  const MovementRestoreError(this.message);

  @override
  List<Object> get props => [message];
}