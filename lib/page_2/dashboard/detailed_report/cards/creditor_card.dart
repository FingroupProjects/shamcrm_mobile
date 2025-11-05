import 'package:crm_task_manager/models/page_2/dashboard/creditors_model.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';

class CreditorCard extends StatelessWidget {
  final Creditor creditor;
  final Function(Creditor) onClick;
  final Function(Creditor) onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const CreditorCard({
    Key? key,
    required this.creditor,
    required this.onClick,
    required this.onLongPress,
    required this.isSelectionMode,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => onClick(creditor),
      onLongPress: () => onLongPress(creditor),
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
                    '${localizations.translate('client') ?? 'Клиент'} ${creditor.name}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('debt_amount') ?? 'debt_amount'}: ${parseNumberToString(creditor.debtAmount)}',
                     style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
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