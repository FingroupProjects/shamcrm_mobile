import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';

abstract class SupplierReturnState extends Equatable {
  const SupplierReturnState();

  @override
  List<Object> get props => [];
}

class SupplierReturnInitial extends SupplierReturnState {}

class SupplierReturnLoading extends SupplierReturnState {}

class SupplierReturnLoaded extends SupplierReturnState {
  final List<IncomingDocument> data;
  final Pagination? pagination;
  final bool hasReachedMax;

  const SupplierReturnLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
  });

  @override
  List<Object> get props => [data, hasReachedMax];
}

class SupplierReturnError extends SupplierReturnState {
  final String message;
  final int? statusCode;

  const SupplierReturnError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class SupplierReturnCreateLoading extends SupplierReturnState {}

class SupplierReturnCreateSuccess extends SupplierReturnState {
  final String message;

  const SupplierReturnCreateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class SupplierReturnCreateError extends SupplierReturnState {
  final String message;
  final int? statusCode;

  const SupplierReturnCreateError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class SupplierReturnUpdateLoading extends SupplierReturnState {}

class SupplierReturnUpdateSuccess extends SupplierReturnState {
  final String message;

  const SupplierReturnUpdateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class SupplierReturnUpdateError extends SupplierReturnState {
  final String message;
  final int? statusCode;

  const SupplierReturnUpdateError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class SupplierReturnDeleteLoading extends SupplierReturnState {}

class SupplierReturnDeleteSuccess extends SupplierReturnState {
  final String message;

  const SupplierReturnDeleteSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class SupplierReturnDeleteError extends SupplierReturnState {
  final String message;
  final int? statusCode;

  const SupplierReturnDeleteError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class SupplierReturnRestoreLoading extends SupplierReturnState {}

class SupplierReturnRestoreSuccess extends SupplierReturnState {
  final String message;

  const SupplierReturnRestoreSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class SupplierReturnRestoreError extends SupplierReturnState {
  final String message;
  final int? statusCode;

  const SupplierReturnRestoreError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}