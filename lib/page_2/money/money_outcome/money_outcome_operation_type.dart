enum MoneyOutcomeOperationType {
  // send_another_cash_register,
  other_expenses,
  supplier_payment,
  client_return,
}

MoneyOutcomeOperationType? getOperationTypeFromString(String? operationTypeString) {
  if (operationTypeString == null) return null;

  try {
    return MoneyOutcomeOperationType.values.firstWhere(
          (e) => e.name == operationTypeString,
    );
  } catch (e) {
    return null;
  }
}
