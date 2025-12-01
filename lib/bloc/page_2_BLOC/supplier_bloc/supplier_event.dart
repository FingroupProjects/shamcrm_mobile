import 'package:crm_task_manager/models/page_2/supplier_model.dart';

abstract class SupplierEvent {}

class FetchSupplier extends SupplierEvent {
  final String? query;
  
  FetchSupplier({this.query});
}

class AddSupplier extends SupplierEvent {
  final Supplier supplier;

  AddSupplier(this.supplier);
}

class UpdateSupplier extends SupplierEvent {
  final Supplier supplier;
  final int id;

  UpdateSupplier(this.supplier, this.id);
}

class DeleteSupplier extends SupplierEvent {
  final int supplierId;

  DeleteSupplier(this.supplierId);
}

class SearchSuppliers extends SupplierEvent {
  final String query;

  SearchSuppliers(this.query);
}

class FilterSuppliers extends SupplierEvent {
  final Map<String, dynamic> filters;

  FilterSuppliers(this.filters);
}

class ClearSupplierFilters extends SupplierEvent {}
