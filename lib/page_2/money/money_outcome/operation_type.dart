enum OperationType {
  send_another_cash_register,
  other_incomes,
  return_supplier,
  client_payment,
}

OperationType? getOperationTypeFromString(String? operationTypeString) {
  if (operationTypeString == null) return null;

  try {
    return OperationType.values.firstWhere(
          (e) => e.name == operationTypeString,
    );
  } catch (e) {
    return null;
  }
}
