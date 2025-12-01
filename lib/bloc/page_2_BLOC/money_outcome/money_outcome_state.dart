part of 'money_outcome_bloc.dart';

sealed class MoneyOutcomeState extends Equatable {
  const MoneyOutcomeState();

  @override
  List<Object?> get props => [];
}

class MoneyOutcomeInitial extends MoneyOutcomeState {}

class MoneyOutcomeLoading extends MoneyOutcomeState {}

class MoneyOutcomeLoaded extends MoneyOutcomeState {
  final List<Document> data;
  final Pagination? pagination;
  final bool hasReachedMax;
  final List<Document>? selectedData;

  const MoneyOutcomeLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
    this.selectedData = const [],
  });

  @override
  List<Object?> get props => [data, pagination, hasReachedMax, selectedData];
}

// --------------------- Errors & Success States ---------------------

class MoneyOutcomeError extends MoneyOutcomeState {
  final String message;
  final int? statusCode;

  const MoneyOutcomeError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Create ---------------------

class MoneyOutcomeCreateLoading extends MoneyOutcomeState {}

class MoneyOutcomeCreateSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeCreateSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MoneyOutcomeCreateError extends MoneyOutcomeState {
  final String message;
  final int? statusCode;

  const MoneyOutcomeCreateError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Update ---------------------

class MoneyOutcomeUpdateLoading extends MoneyOutcomeState {}

class MoneyOutcomeUpdateSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeUpdateSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MoneyOutcomeUpdateError extends MoneyOutcomeState {
  final String message;
  final int? statusCode;

  const MoneyOutcomeUpdateError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Delete ---------------------

class MoneyOutcomeDeleteLoading extends MoneyOutcomeState {}

class MoneyOutcomeDeleteSuccess extends MoneyOutcomeState {
  final String message;
  final bool reload;

  const MoneyOutcomeDeleteSuccess(this.message, {this.reload = true});

  @override
  List<Object?> get props => [message, reload];
}

class MoneyOutcomeDeleteError extends MoneyOutcomeState {
  final String message;
  final int? statusCode;

  const MoneyOutcomeDeleteError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Toggle One Approve ---------------------

class MoneyOutcomeToggleOneApproveSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeToggleOneApproveSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MoneyOutcomeToggleOneApproveError extends MoneyOutcomeState {
  final String message;
  final int? statusCode;

  const MoneyOutcomeToggleOneApproveError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Approve Mass ---------------------

class MoneyOutcomeApproveMassSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeApproveMassSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MoneyOutcomeApproveMassError extends MoneyOutcomeState {
  final String message;
  final int? statusCode;

  const MoneyOutcomeApproveMassError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Disapprove Mass ---------------------

class MoneyOutcomeDisapproveMassSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeDisapproveMassSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MoneyOutcomeDisapproveMassError extends MoneyOutcomeState {
  final String message;
  final int? statusCode;

  const MoneyOutcomeDisapproveMassError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Delete Mass ---------------------

class MoneyOutcomeDeleteMassSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeDeleteMassSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MoneyOutcomeDeleteMassError extends MoneyOutcomeState {
  final String message;
  final int? statusCode;

  const MoneyOutcomeDeleteMassError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Restore Mass ---------------------

class MoneyOutcomeRestoreMassSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeRestoreMassSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MoneyOutcomeRestoreMassError extends MoneyOutcomeState {
  final String message;
  final int? statusCode;

  const MoneyOutcomeRestoreMassError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// ---------------------  Update Then Toggle One Approve ---------------------
class MoneyOutcomeUpdateThenToggleOneApproveSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeUpdateThenToggleOneApproveSuccess(this.message);

  @override
  List<Object?> get props => [message];
}