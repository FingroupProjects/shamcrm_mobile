abstract class CashRegisterDialogEvent {}

class LoadCashRegistersForDialog extends CashRegisterDialogEvent {
  final String? search;
  LoadCashRegistersForDialog({this.search});
}

class SearchCashRegistersForDialog extends CashRegisterDialogEvent {
  final String? search;
  SearchCashRegistersForDialog({this.search});
}

