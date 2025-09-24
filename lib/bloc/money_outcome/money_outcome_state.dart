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

class MoneyOutcomeError extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeError(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeCreateLoading extends MoneyOutcomeState {}

class MoneyOutcomeCreateSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeCreateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeCreateError extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeCreateError(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeUpdateLoading extends MoneyOutcomeState {}

class MoneyOutcomeUpdateSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeUpdateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeUpdateError extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeUpdateError(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeDeleteLoading extends MoneyOutcomeState {}

class MoneyOutcomeDeleteSuccess extends MoneyOutcomeState {
  final String message;
  final bool reload;

  const MoneyOutcomeDeleteSuccess(this.message, {this.reload = true});

  @override
  List<Object> get props => [message, reload];
}

class MoneyOutcomeDeleteError extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeDeleteError(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeRestoreLoading extends MoneyOutcomeState {}

class MoneyOutcomeRestoreSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeRestoreSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeRestoreError extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeRestoreError(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeNavigateToAdd extends MoneyOutcomeState {}

class MoneyOutcomeToggleOneApproveSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeToggleOneApproveSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeToggleOneApproveError extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeToggleOneApproveError(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeApproveMassSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeApproveMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeApproveMassError extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeApproveMassError(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeDisapproveMassSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeDisapproveMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeDisapproveMassError extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeDisapproveMassError(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeDeleteMassSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeDeleteMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeDeleteMassError extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeDeleteMassError(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeRestoreMassSuccess extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeRestoreMassSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyOutcomeRestoreMassError extends MoneyOutcomeState {
  final String message;

  const MoneyOutcomeRestoreMassError(this.message);

  @override
  List<Object> get props => [message];
}