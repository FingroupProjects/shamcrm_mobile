abstract class SupplierOpeningsEvent {}

class LoadSupplierOpenings extends SupplierOpeningsEvent {
  LoadSupplierOpenings();
}

class RefreshSupplierOpenings extends SupplierOpeningsEvent {
  RefreshSupplierOpenings();
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

class EditSupplierOpening extends SupplierOpeningsEvent {
  final int id;
  final int supplierId;
  final double ourDuty;
  final double debtToUs;

  EditSupplierOpening({
    required this.id,
    required this.supplierId,
    required this.ourDuty,
    required this.debtToUs,
  });
}

// События для списка поставщиков (для диалога)
class LoadSupplierOpeningsSuppliers extends SupplierOpeningsEvent {}

class RefreshSupplierOpeningsSuppliers extends SupplierOpeningsEvent {}
