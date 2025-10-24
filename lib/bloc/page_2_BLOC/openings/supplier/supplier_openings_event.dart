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
