import 'package:crm_task_manager/models/page_2/dashboard/debtors_model.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';

class DebtorsCard extends StatelessWidget {
  final Debtor debtor;
  final Function(Debtor) onClick;
  final Function(Debtor) onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const DebtorsCard({
    Key? key,
    required this.debtor,
    required this.onClick,
    required this.onLongPress,
    required this.isSelectionMode,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => onClick(debtor),
      onLongPress: () => onLongPress(debtor),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDDE8F5) : const Color(0xFFE9EDF5),
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
                    '${localizations.translate('debtor_name_details') ?? 'Название'}: ${debtor.name}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('debt_amount') ?? 'debt_amount'}: ${parseNumberToString(debtor.debtAmount)}',
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
            if (isSelectionMode) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: Color(0xff1E2E52),
                  size: 24,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}