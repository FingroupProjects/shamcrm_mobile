import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';

abstract class ManufactureState extends Equatable {
  const ManufactureState();

  @override
  List<Object> get props => [];
}

class ManufactureInitial extends ManufactureState {}

class ManufactureLoading extends ManufactureState {}

class ManufactureLoaded extends ManufactureState {
  final List<IncomingDocument> data;
  final Pagination? pagination;
  final bool hasReachedMax;
  final List<IncomingDocument>? selectedData;

  const ManufactureLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
    this.selectedData = const [],
  });

  @override
  List<Object> get props => [data, hasReachedMax, selectedData ?? []];
}

class ManufactureError extends ManufactureState {
  final String message;
  final int? statusCode;

  const ManufactureError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class ManufactureCreateLoading extends ManufactureState {}

class ManufactureCreateSuccess extends ManufactureState {
  final String message;

  const ManufactureCreateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ManufactureCreateError extends ManufactureState {
  final String message;
  final int? statusCode;

  const ManufactureCreateError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class ManufactureUpdateLoading extends ManufactureState {}

class ManufactureUpdateSuccess extends ManufactureState {
  final String message;

  const ManufactureUpdateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ManufactureUpdateError extends ManufactureState {
  final String message;
  final int? statusCode;

  const ManufactureUpdateError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class ManufactureDeleteLoading extends ManufactureState {}

class ManufactureDeleteSuccess extends ManufactureState {
  final String message;
  final bool shouldReload;

  const ManufactureDeleteSuccess(this.message, {this.shouldReload = true});

  @override
  List<Object> get props => [message, shouldReload];
}

class ManufactureDeleteError extends ManufactureState {
  final String message;
  final int? statusCode;

  const ManufactureDeleteError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

class ManufactureRestoreLoading extends ManufactureState {}

class ManufactureRestoreSuccess extends ManufactureState {
  final String message;

  const ManufactureRestoreSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ManufactureRestoreError extends ManufactureState {
  final String message;
  final int? statusCode;

  const ManufactureRestoreError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

// Mass Approve States
class ManufactureApproveMassLoading extends ManufactureState {}

class ManufactureApproveMassSuccess extends ManufactureState {
  final String message;

  const ManufactureApproveMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ManufactureApproveMassError extends ManufactureState {
  final String message;
  final int? statusCode;

  const ManufactureApproveMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

// Mass Disapprove States
class ManufactureDisapproveMassLoading extends ManufactureState {}

class ManufactureDisapproveMassSuccess extends ManufactureState {
  final String message;

  const ManufactureDisapproveMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ManufactureDisapproveMassError extends ManufactureState {
  final String message;
  final int? statusCode;

  const ManufactureDisapproveMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

// Mass Delete States
class ManufactureDeleteMassLoading extends ManufactureState {}

class ManufactureDeleteMassSuccess extends ManufactureState {
  final String message;

  const ManufactureDeleteMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ManufactureDeleteMassError extends ManufactureState {
  final String message;
  final int? statusCode;

  const ManufactureDeleteMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}

// Mass Restore States
class ManufactureRestoreMassLoading extends ManufactureState {}

class ManufactureRestoreMassSuccess extends ManufactureState {
  final String message;

  const ManufactureRestoreMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ManufactureRestoreMassError extends ManufactureState {
  final String message;
  final int? statusCode;

  const ManufactureRestoreMassError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
}
