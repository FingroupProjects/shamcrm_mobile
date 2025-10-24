abstract class CashRegisterOpeningsEvent {}

class LoadCashRegisterOpenings extends CashRegisterOpeningsEvent {
  final int page;
  final String? search;
  final Map<String, dynamic>? filter;

  LoadCashRegisterOpenings({
    this.page = 1,
    this.search,
    this.filter,
  });
}

class RefreshCashRegisterOpenings extends CashRegisterOpeningsEvent {
  final String? search;
  final Map<String, dynamic>? filter;

  RefreshCashRegisterOpenings({
    this.search,
    this.filter,
  });
}
