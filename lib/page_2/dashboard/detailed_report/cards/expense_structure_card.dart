import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/page_2/dashboard/expense_structure_content.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class ExpenseStructureCard extends StatelessWidget {
  final ExpenseItem expenseItem;

  const ExpenseStructureCard({
    Key? key,
    required this.expenseItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${localizations.translate('name')}: ${expenseItem.articleName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff1E2E52),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${localizations.translate('amount')}: ${expenseItem.formattedSum}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff99A4BA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
