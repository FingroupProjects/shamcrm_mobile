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

class DeleteCashRegisterOpening extends CashRegisterOpeningsEvent {
  final int id;

  DeleteCashRegisterOpening({required this.id});
}

class LoadCashRegisterLeads extends CashRegisterOpeningsEvent {}

class RefreshCashRegisterLeads extends CashRegisterOpeningsEvent {}

class CreateCashRegisterOpening extends CashRegisterOpeningsEvent {
  final int cashRegisterId;
  final String sum;

  CreateCashRegisterOpening({
    required this.cashRegisterId,
    required this.sum,
  });
}

class UpdateCashRegisterOpening extends CashRegisterOpeningsEvent {
  final int cashRegisterId;
  final String sum;

  UpdateCashRegisterOpening({
    required this.cashRegisterId,
    required this.sum,
  });
}