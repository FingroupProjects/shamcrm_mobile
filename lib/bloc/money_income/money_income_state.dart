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
  final List<Document>? selectedData;

  const MoneyIncomeLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
    this.selectedData = const [],
  });

  @override
  List<Object?> get props => [data, pagination, hasReachedMax, selectedData];
}

// --------------------- Errors & Success States ---------------------

class MoneyIncomeError extends MoneyIncomeState {
  final String message;
  final int? statusCode;

  const MoneyIncomeError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Create ---------------------

class MoneyIncomeCreateLoading extends MoneyIncomeState {}

class MoneyIncomeCreateSuccess extends MoneyIncomeState {
  final String message;

  const MoneyIncomeCreateSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MoneyIncomeCreateError extends MoneyIncomeState {
  final String message;
  final int? statusCode;

  const MoneyIncomeCreateError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Update ---------------------

class MoneyIncomeUpdateLoading extends MoneyIncomeState {}

class MoneyIncomeUpdateSuccess extends MoneyIncomeState {
  final String message;

  const MoneyIncomeUpdateSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MoneyIncomeUpdateError extends MoneyIncomeState {
  final String message;
  final int? statusCode;

  const MoneyIncomeUpdateError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Delete ---------------------

class MoneyIncomeDeleteLoading extends MoneyIncomeState {}

class MoneyIncomeDeleteSuccess extends MoneyIncomeState {
  final String message;
  final bool reload;

  const MoneyIncomeDeleteSuccess(this.message, {this.reload = true});

  @override
  List<Object?> get props => [message, reload];
}

class MoneyIncomeDeleteError extends MoneyIncomeState {
  final String message;
  final int? statusCode;

  const MoneyIncomeDeleteError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Toggle One Approve ---------------------

class MoneyIncomeToggleOneApproveSuccess extends MoneyIncomeState {
  final String message;

  const MoneyIncomeToggleOneApproveSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MoneyIncomeToggleOneApproveError extends MoneyIncomeState {
  final String message;
  final int? statusCode;

  const MoneyIncomeToggleOneApproveError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Approve Mass ---------------------

class MoneyIncomeApproveMassSuccess extends MoneyIncomeState {
  final String message;

  const MoneyIncomeApproveMassSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MoneyIncomeApproveMassError extends MoneyIncomeState {
  final String message;
  final int? statusCode;

  const MoneyIncomeApproveMassError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Disapprove Mass ---------------------

class MoneyIncomeDisapproveMassSuccess extends MoneyIncomeState {
  final String message;

  const MoneyIncomeDisapproveMassSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MoneyIncomeDisapproveMassError extends MoneyIncomeState {
  final String message;
  final int? statusCode;

  const MoneyIncomeDisapproveMassError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Delete Mass ---------------------

class MoneyIncomeDeleteMassSuccess extends MoneyIncomeState {
  final String message;

  const MoneyIncomeDeleteMassSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MoneyIncomeDeleteMassError extends MoneyIncomeState {
  final String message;
  final int? statusCode;

  const MoneyIncomeDeleteMassError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// --------------------- Restore Mass ---------------------

class MoneyIncomeRestoreMassSuccess extends MoneyIncomeState {
  final String message;

  const MoneyIncomeRestoreMassSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MoneyIncomeRestoreMassError extends MoneyIncomeState {
  final String message;
  final int? statusCode;

  const MoneyIncomeRestoreMassError(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}
