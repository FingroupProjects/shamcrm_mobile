part of 'income_bloc.dart';

enum IncomeStatus {
  initial,
  initialLoading,
  initialLoaded,
  initialError,
  loadingMore,
}

class IncomeState extends Equatable {
  const IncomeState({
    this.status = IncomeStatus.initial,
    this.incomes = const [],
    this.pagination,
    this.currentPage = 1,
    this.searchQuery,
    this.hasReachedMax = false,
    this.errorMessage,
  });

  final IncomeStatus status;
  final List<IncomeModel> incomes;
  final PaginationModel? pagination;
  final int currentPage;
  final String? searchQuery;
  final bool hasReachedMax;
  final String? errorMessage;

  IncomeState copyWith({
    IncomeStatus? status,
    List<IncomeModel>? incomes,
    PaginationModel? pagination,
    int? currentPage,
    String? searchQuery,
    bool? hasReachedMax,
    String? errorMessage,
  }) {
    return IncomeState(
      status: status ?? this.status,
      incomes: incomes ?? this.incomes,
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
    incomes,
    pagination,
    currentPage,
    searchQuery,
    hasReachedMax,
    errorMessage,
  ];
}
