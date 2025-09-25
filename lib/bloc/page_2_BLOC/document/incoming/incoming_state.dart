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
  final int? statusCode;

  const IncomingError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
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
  final int? statusCode;

  const IncomingCreateError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
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
  final int? statusCode;

  const IncomingUpdateError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
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
  final int? statusCode;

  const IncomingDeleteError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
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
  final int? statusCode;

  const IncomingRestoreError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}