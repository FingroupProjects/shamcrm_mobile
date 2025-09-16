part of 'money_income_bloc.dart';

sealed class MoneyIncomeState extends Equatable {
  const MoneyIncomeState();

  @override
  List<Object?> get props => [];
}

class MoneyIncomeInitial extends MoneyIncomeState {}

class MoneyIncomeLoading extends MoneyIncomeState {}

class MoneyIncomeLoaded extends MoneyIncomeState {
  final List<Document> data;
  final Pagination? pagination;
  final bool hasReachedMax;

  const MoneyIncomeLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [data, pagination, hasReachedMax];
}

class MoneyIncomeError extends MoneyIncomeState {
  final String message;

  const MoneyIncomeError(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyIncomeCreateLoading extends MoneyIncomeState {}

class MoneyIncomeCreateSuccess extends MoneyIncomeState {
  final String message;

  const MoneyIncomeCreateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyIncomeCreateError extends MoneyIncomeState {
  final String message;

  const MoneyIncomeCreateError(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyIncomeUpdateLoading extends MoneyIncomeState {}

class MoneyIncomeUpdateSuccess extends MoneyIncomeState {
  final String message;

  const MoneyIncomeUpdateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyIncomeUpdateError extends MoneyIncomeState {
  final String message;

  const MoneyIncomeUpdateError(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyIncomeDeleteLoading extends MoneyIncomeState {}

class MoneyIncomeDeleteSuccess extends MoneyIncomeState {
  final String message;

  const MoneyIncomeDeleteSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyIncomeDeleteError extends MoneyIncomeState {
  final String message;

  const MoneyIncomeDeleteError(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyIncomeRestoreLoading extends MoneyIncomeState {}

class MoneyIncomeRestoreSuccess extends MoneyIncomeState {
  final String message;

  const MoneyIncomeRestoreSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyIncomeRestoreError extends MoneyIncomeState {
  final String message;

  const MoneyIncomeRestoreError(this.message);

  @override
  List<Object> get props => [message];
}

class MoneyIncomeNavigateToAdd extends MoneyIncomeState {}