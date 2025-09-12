import 'package:crm_task_manager/models/page_2/supplier_model.dart';

abstract class SupplierState {}

class SupplierInitial extends SupplierState {}

class SupplierLoading extends SupplierState {}

class SupplierLoaded extends SupplierState {
  final List<Supplier> supplierList;

  SupplierLoaded(this.supplierList);
}

class SupplierError extends SupplierState {
  final String message;

  SupplierError(this.message);
}

class SupplierSuccess extends SupplierState {
  final String message;

  SupplierSuccess(this.message);
}

