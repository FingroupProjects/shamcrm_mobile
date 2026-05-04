enum LocalOperationStatus {
  pending,
  syncing,
  synced,
  failed,
  conflict,
}

extension LocalOperationStatusX on LocalOperationStatus {
  String get value => name;

  static LocalOperationStatus fromValue(String value) {
    return LocalOperationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => LocalOperationStatus.pending,
    );
  }
}
