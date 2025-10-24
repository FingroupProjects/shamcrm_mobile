abstract class SupplierOpeningsEvent {}

class LoadSupplierOpenings extends SupplierOpeningsEvent {
  final int page;
  final String? search;
  final Map<String, dynamic>? filter;

  LoadSupplierOpenings({
    this.page = 1,
    this.search,
    this.filter,
  });
}

class RefreshSupplierOpenings extends SupplierOpeningsEvent {
  final String? search;
  final Map<String, dynamic>? filter;

  RefreshSupplierOpenings({
    this.search,
    this.filter,
  });
}

class DeleteSupplierOpening extends SupplierOpeningsEvent {
  final int id;

  DeleteSupplierOpening({required this.id});
}

class CreateSupplierOpening extends SupplierOpeningsEvent {
  final int supplierId;
  final double ourDuty;
  final double debtToUs;

  CreateSupplierOpening({
    required this.supplierId,
    required this.ourDuty,
    required this.debtToUs,
  });
}

// События для списка поставщиков (для диалога)
class LoadSupplierOpeningsSuppliers extends SupplierOpeningsEvent {}

class RefreshSupplierOpeningsSuppliers extends SupplierOpeningsEvent {}
