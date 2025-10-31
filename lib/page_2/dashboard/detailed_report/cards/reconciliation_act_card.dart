import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:crm_task_manager/utils/global_fun.dart';

import '../../../../models/page_2/dashboard/act_of_reconciliation_model.dart';

class ReconciliationActCard extends StatelessWidget {
  final ReconciliationItem reconciliationItem;
  final Function(ReconciliationItem) onClick;
  final Function(ReconciliationItem) onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const ReconciliationActCard({
    Key? key,
    required this.reconciliationItem,
    required this.onClick,
    required this.onLongPress,
    required this.isSelectionMode,
    required this.isSelected,
  }) : super(key: key);

  String _formatDate(DateTime? date, AppLocalizations localizations) {
    if (date == null) return localizations.translate('not_updated');

    return DateFormat('dd.MM.yyyy HH:mm', 'ru_RU').format(date);
  }

  String _getMovementTypeText(String? movementType, AppLocalizations localizations) {
    switch (movementType?.toLowerCase()) {
      case 'income':
        return localizations.translate('income');
      case 'outcome':
        return localizations.translate('outcome');
      default:
        return movementType ?? localizations.translate('not_specified');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => onClick(reconciliationItem),
      onLongPress: () => onLongPress(reconciliationItem),
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
                  // Тип движения
                  Text(
                    '${localizations.translate('document_type')}: ${_getMovementTypeText(reconciliationItem.movementType, localizations)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Контрагент
                  if (reconciliationItem.counterparty != null) ...[
                    Text(
                      '${localizations.translate('counterparty')}: ${reconciliationItem.counterparty!.name ?? localizations.translate('not_specified')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Сумма
                  Row(
                    children: [
                      Text(
                        '${localizations.translate('sum')}:',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        parseNumberToString(reconciliationItem.sum, nullValue: ''),
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ],
                  ),

                  // Сумма продажи (если есть)
                  if (reconciliationItem.saleSum != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${localizations.translate('sale_sum')}:',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w400,
                            color: Color(0xff99A4BA),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          parseNumberToString(reconciliationItem.saleSum, nullValue: ''),
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w400,
                            color: Color(0xff99A4BA),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 4),

                  // Дата
                  Row(
                    children: [
                      Text(
                        '${localizations.translate('date')}:',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(reconciliationItem.date, localizations),
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelectionMode) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: const Color(0xff1E2E52),
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