import '../../../../models/page_2/openings/cash_register_openings_model.dart';

abstract class CashRegisterOpeningsState {}

class CashRegisterOpeningsInitial extends CashRegisterOpeningsState {}

class CashRegisterOpeningsLoading extends CashRegisterOpeningsState {}

class CashRegisterOpeningsLoaded extends CashRegisterOpeningsState {
  final List<CashRegisterOpening> cashRegisters;
  final bool hasReachedMax;
  final Pagination pagination;

  CashRegisterOpeningsLoaded({
    required this.cashRegisters,
    required this.hasReachedMax,
    required this.pagination,
  });

  CashRegisterOpeningsLoaded copyWith({
    List<CashRegisterOpening>? cashRegisters,
    bool? hasReachedMax,
    Pagination? pagination,
  }) {
    return CashRegisterOpeningsLoaded(
      cashRegisters: cashRegisters ?? this.cashRegisters,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      pagination: pagination ?? this.pagination,
    );
  }
}

class CashRegisterOpeningsError extends CashRegisterOpeningsState {
  final String message;

  CashRegisterOpeningsError({required this.message});
}

class CashRegisterOpeningsPaginationError extends CashRegisterOpeningsState {
  final String message;

  CashRegisterOpeningsPaginationError({required this.message});
}

class CashRegisterLeadsLoading extends CashRegisterOpeningsState {}

class CashRegisterLeadsLoaded extends CashRegisterOpeningsState {
  final List<CashRegister> cashRegisters;

  CashRegisterLeadsLoaded({required this.cashRegisters});
}

class CashRegisterLeadsError extends CashRegisterOpeningsState {
  final String message;

  CashRegisterLeadsError({required this.message});
}

class Pagination {
  final int total;
  final int count;
  final int per_page;
  final int current_page;
  final int total_pages;

  Pagination({
    required this.total,
    required this.count,
    required this.per_page,
    required this.current_page,
    required this.total_pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] as int,
      count: json['count'] as int,
      per_page: json['per_page'] as int,
      current_page: json['current_page'] as int,
      total_pages: json['total_pages'] as int,
    );
  }
}
