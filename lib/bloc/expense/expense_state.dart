part of 'expense_bloc.dart';

enum ExpenseStatus {
  initial,
  initialLoading,
  initialLoaded,
  initialError,
  loadingMore,
}

class ExpenseState extends Equatable {
  const ExpenseState({
    this.status = ExpenseStatus.initial,
    this.expenses = const [],
    this.pagination,
    this.currentPage = 1,
    this.searchQuery,
    this.hasReachedMax = false,
    this.errorMessage,
  });

  final ExpenseStatus status;
  final List<ExpenseModel> expenses;
  final PaginationModel? pagination;
  final int currentPage;
  final String? searchQuery;
  final bool hasReachedMax;
  final String? errorMessage;

  ExpenseState copyWith({
    ExpenseStatus? status,
    List<ExpenseModel>? expenses,
    PaginationModel? pagination,
    int? currentPage,
    String? searchQuery,
    bool? hasReachedMax,
    String? errorMessage,
  }) {
    return ExpenseState(
      status: status ?? this.status,
      expenses: expenses ?? this.expenses,
      pagination: pagination ?? this.pagination,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    expenses,
    pagination,
    currentPage,
    searchQuery,
    hasReachedMax,
    errorMessage,
  ];
}
