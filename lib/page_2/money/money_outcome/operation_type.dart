enum OperationType {
  send_another_cash_register,
  other_expenses,
  supplier_payment,
  client_return,
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
