part of 'income_bloc.dart';

sealed class IncomeEvent extends Equatable {
  const IncomeEvent();

  @override
  List<Object?> get props => [];
}

class FetchIncomes extends IncomeEvent {
  final String? query;

  const FetchIncomes({this.query});

  @override
  List<Object?> get props => [query];
}

class LoadMoreIncomes extends IncomeEvent {
  const LoadMoreIncomes();
}

class RefreshIncomes extends IncomeEvent {
  const RefreshIncomes();
}

class SearchIncomes extends IncomeEvent {
  final String? query;

  const SearchIncomes({this.query});

  @override
  List<Object?> get props => [query];
}

class DeleteIncome extends IncomeEvent {
  final int id;

  const DeleteIncome(this.id);

  @override
  List<Object?> get props => [id];
}
