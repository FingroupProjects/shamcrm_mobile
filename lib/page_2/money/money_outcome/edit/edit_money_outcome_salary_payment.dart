import 'package:crm_task_manager/models/money/money_outcome_document_model.dart';
import 'package:flutter/material.dart';

import '../salary_payment_form.dart';

class EditMoneyOutcomeSalaryPayment extends StatelessWidget {
  final Document document;

  const EditMoneyOutcomeSalaryPayment({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    return SalaryPaymentForm(document: document);
  }
}
