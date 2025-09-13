import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';

abstract class IncomingState extends Equatable {
  const IncomingState();

  @override
  List<Object> get props => [];
}

class IncomingInitial extends IncomingState {}

class IncomingLoading extends IncomingState {}

class IncomingLoaded extends IncomingState {
  final List<IncomingDocument> data;
  final Pagination? pagination;
  final bool hasReachedMax;

  const IncomingLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
  });

  @override
  List<Object> get props => [data, hasReachedMax];
}

class IncomingError extends IncomingState {
  final String message;

  const IncomingError(this.message);

  @override
  List<Object> get props => [message];
}

class IncomingCreateLoading extends IncomingState {}

class IncomingCreateSuccess extends IncomingState {
  final String message;

  const IncomingCreateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class IncomingCreateError extends IncomingState {
  final String message;

  const IncomingCreateError(this.message);

  @override
  List<Object> get props => [message];
}
class IncomingUpdateLoading extends IncomingState {}

class IncomingUpdateSuccess extends IncomingState {
  final String message;

  const IncomingUpdateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class IncomingUpdateError extends IncomingState {
  final String message;

  const IncomingUpdateError(this.message);

  @override
  List<Object> get props => [message];
}

class IncomingDeleteLoading extends IncomingState {}

class IncomingDeleteSuccess extends IncomingState {
  final String message;

  const IncomingDeleteSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class IncomingDeleteError extends IncomingState {
  final String message;

  const IncomingDeleteError(this.message);

  @override
  List<Object> get props => [message];
}


class IncomingRestoreLoading extends IncomingState {}

class IncomingRestoreSuccess extends IncomingState {
  final String message;

  const IncomingRestoreSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class IncomingRestoreError extends IncomingState {
  final String message;

  const IncomingRestoreError(this.message);

  @override
  List<Object> get props => [message];
}
