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

  const MoneyOutcomeLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [data, pagination, hasReachedMax];
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

  const MoneyOutcomeDeleteSuccess(this.message);

  @override
  List<Object> get props => [message];
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