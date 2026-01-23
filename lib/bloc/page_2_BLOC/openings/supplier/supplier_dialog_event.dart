abstract class SupplierDialogEvent {}

class LoadSuppliersForDialog extends SupplierDialogEvent {
  final String? search;
  LoadSuppliersForDialog({this.search});
}

class SearchSuppliersForDialog extends SupplierDialogEvent {
  final String? search;
  SearchSuppliersForDialog({this.search});
}

