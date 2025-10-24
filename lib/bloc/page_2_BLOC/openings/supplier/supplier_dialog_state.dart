import '../../../../models/page_2/opening_supplier_model.dart';

abstract class SupplierDialogState {}

class SupplierDialogInitial extends SupplierDialogState {}

class SupplierDialogLoading extends SupplierDialogState {}

class SupplierDialogLoaded extends SupplierDialogState {
  final List<Supplier> suppliers;

  SupplierDialogLoaded({required this.suppliers});
}

class SupplierDialogError extends SupplierDialogState {
  final String message;

  SupplierDialogError({required this.message});
}

