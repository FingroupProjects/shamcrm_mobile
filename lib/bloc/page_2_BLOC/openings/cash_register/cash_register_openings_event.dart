abstract class CashRegisterOpeningsEvent {}

class LoadCashRegisterOpenings extends CashRegisterOpeningsEvent {
  LoadCashRegisterOpenings();
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
  final int id;

  UpdateCashRegisterOpening({
    required this.id,
    required this.cashRegisterId,
    required this.sum,
  });
}