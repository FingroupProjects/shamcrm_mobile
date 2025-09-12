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