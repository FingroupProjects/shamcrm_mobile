import '../../../../models/page_2/openings/cash_register_openings_model.dart';

abstract class CashRegisterOpeningsState {}

class CashRegisterOpeningsInitial extends CashRegisterOpeningsState {}

class CashRegisterOpeningsLoading extends CashRegisterOpeningsState {}

class CashRegisterOpeningsLoaded extends CashRegisterOpeningsState {
  final List<CashRegisterOpening> cashRegisters;

  CashRegisterOpeningsLoaded({
    required this.cashRegisters,
  });

  CashRegisterOpeningsLoaded copyWith({
    List<CashRegisterOpening>? cashRegisters,
    bool? hasReachedMax,
    Pagination? pagination,
  }) {
    return CashRegisterOpeningsLoaded(
      cashRegisters: cashRegisters ?? this.cashRegisters,
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

// Состояние для ошибок операций (создание, редактирование, удаление)
// Не влияет на отображение контента, используется только для snackbar
class CashRegisterOpeningsOperationError extends CashRegisterOpeningsState {
  final String message;
  final CashRegisterOpeningsState previousState;

  CashRegisterOpeningsOperationError({
    required this.message,
    required this.previousState,
  });
}

// Состояние загрузки для операции создания
class CashRegisterOpeningCreating extends CashRegisterOpeningsState {}

// Состояние успешного создания
class CashRegisterOpeningCreateSuccess extends CashRegisterOpeningsState {}

// Состояние ошибки создания
class CashRegisterOpeningCreateError extends CashRegisterOpeningsState {
  final String message;

  CashRegisterOpeningCreateError({required this.message});
}

// Состояние загрузки для операции обновления
class CashRegisterOpeningUpdating extends CashRegisterOpeningsState {}

class CashRegisterOpeningUpdateSuccess extends CashRegisterOpeningsState {}

// Deprecated: используйте CashRegisterOpeningsOperationError
class CashRegisterOpeningUpdateError extends CashRegisterOpeningsState {
  final String message;

  CashRegisterOpeningUpdateError({required this.message});
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
