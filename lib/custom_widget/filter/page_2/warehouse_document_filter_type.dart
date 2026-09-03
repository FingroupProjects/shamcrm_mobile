enum WarehouseDocumentFilterType {
  incoming,
  clientSale,
  clientReturn,
  movement,
  writeOff,
  supplierReturn,
}

extension WarehouseDocumentFilterTypeX on WarehouseDocumentFilterType {
  bool get showWarehouse => this != WarehouseDocumentFilterType.movement;

  bool get showSenderRecipient => this == WarehouseDocumentFilterType.movement;

  bool get showSupplier =>
      this == WarehouseDocumentFilterType.incoming ||
      this == WarehouseDocumentFilterType.supplierReturn;

  bool get showClient =>
      this == WarehouseDocumentFilterType.clientSale ||
      this == WarehouseDocumentFilterType.clientReturn;

  String get prefsPrefix => 'wh_doc_filter_${name}_';
}
