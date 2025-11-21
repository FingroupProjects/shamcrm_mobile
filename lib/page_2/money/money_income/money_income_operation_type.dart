enum MoneyIncomeOperationType {
  send_another_cash_register,
  other_incomes,
  return_supplier,
  client_payment,
}

MoneyIncomeOperationType? getOperationTypeFromString(String? operationTypeString) {
  if (operationTypeString == null) return null;

  try {
    return MoneyIncomeOperationType.values.firstWhere(
          (e) => e.name == operationTypeString,
    );
  } catch (e) {
    return null;
  }
}
