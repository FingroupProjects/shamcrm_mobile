// cash_desk_state.dart
part of 'cash_desk_bloc.dart';

enum CashDeskStatus {
  initial,
  initialLoading,
  initialError,
  initialLoaded,
  loadingMore,
  loadMoreError,
  refreshing,
  refreshError,
  searchError,
}

class CashDeskState extends Equatable {
  const CashDeskState({
    this.status = CashDeskStatus.initial,
    this.cashRegisters = const [],
    this.pagination,
    this.currentPage = 1,
    this.searchQuery,
    this.hasReachedMax = false,
    this.errorMessage,
  });

  final CashDeskStatus status;
  final List<CashRegisterModel> cashRegisters;
  final PaginationModel? pagination;
  final int currentPage;
  final String? searchQuery;
  final bool hasReachedMax;
  final String? errorMessage;

  @override
  List<Object?> get props => [
    status,
    cashRegisters,
    pagination,
    currentPage,
    searchQuery,
    hasReachedMax,
    errorMessage,
  ];

  CashDeskState copyWith({
    CashDeskStatus? status,
    List<CashRegisterModel>? cashRegisters,
    PaginationModel? pagination,
    int? currentPage,
    String? searchQuery,
    bool? hasReachedMax,
    String? errorMessage,
  }) {
    return CashDeskState(
      status: status ?? this.status,
      cashRegisters: cashRegisters ?? this.cashRegisters,
      pagination: pagination ?? this.pagination,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
