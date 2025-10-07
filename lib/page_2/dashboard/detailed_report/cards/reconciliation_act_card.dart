import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:intl/intl.dart';

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

  String _formatAmount(String? amount) {
    if (amount == null || amount.isEmpty) return '0.00';
    
    try {
      double amountValue = double.parse(amount);
      return NumberFormat('#,##0.00', 'ru_RU').format(amountValue);
    } catch (e) {
      return amount;
    }
  }

  String _formatDate(DateTime? date, AppLocalizations localizations) {
    if (date == null) return localizations.translate('not_updated');
    
    return DateFormat('dd.MM.yyyy HH:mm', 'ru_RU').format(date);
  }

  Color _getMovementTypeColor(String? movementType) {

      return const Color(0xff64748B);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${localizations.translate('movement_type')}: ${_getMovementTypeText(reconciliationItem.movementType, localizations)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: _getMovementTypeColor(reconciliationItem.movementType),
                    ),
                  ),
                ),
                if (isSelectionMode) ...[
                  Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: Color(0xff1E2E52),
                    size: 20,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            
            // Контрагент
            if (reconciliationItem.counterparty != null) ...[
              Row(
                children: [
                  Text(
                    '${localizations.translate('counterparty')}:',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reconciliationItem.counterparty!.name ?? localizations.translate('not_specified'),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Суммы
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${localizations.translate('sum')}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                      Text(
                        _formatAmount(reconciliationItem.sum),
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ],
                  ),
                ),
                if (reconciliationItem.saleSum != null) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${localizations.translate('sale_sum')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w400,
                            color: Color(0xff99A4BA),
                          ),
                        ),
                        Text(
                          _formatAmount(reconciliationItem.saleSum),
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            color: Color(0xff10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Дата
            Row(
              children: [
                Text(
                  '${localizations.translate('date')}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff99A4BA),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(reconciliationItem.date, localizations),
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff1E2E52),
                  ),
                ),
              ],
            ),

            // // ID и модель
            // if (reconciliationItem.modelType != null || reconciliationItem.id != null) ...[
            //   const SizedBox(height: 4),
            //   Row(
            //     children: [
            //       if (reconciliationItem.id != null) ...[
            //         Text(
            //           'ID: ${reconciliationItem.id}',
            //           style: TextStyle(
            //             fontSize: 11,
            //             fontFamily: 'Gilroy',
            //             fontWeight: FontWeight.w400,
            //             color: Color(0xff99A4BA),
            //           ),
            //         ),
            //         const SizedBox(width: 12),
            //       ],
            //       if (reconciliationItem.modelType != null) ...[
            //         Text(
            //           '${localizations.translate('model')}: ${reconciliationItem.modelType}',
            //           style: TextStyle(
            //             fontSize: 11,
            //             fontFamily: 'Gilroy',
            //             fontWeight: FontWeight.w400,
            //             color: Color(0xff99A4BA),
            //           ),
            //         ),
            //       ],
            //     ],
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}
