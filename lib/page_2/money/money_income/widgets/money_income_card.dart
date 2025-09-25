import 'package:crm_task_manager/page_2/money/money_income/money_income_operation_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/models/money/money_income_document_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/page_2/money/money_income/widgets/money_income_deletion.dart';
import 'package:crm_task_manager/bloc/money_income/money_income_bloc.dart';
import 'package:intl/intl.dart';

class MoneyIncomeCard extends StatelessWidget {
  final Document document;
  final Function(Document) onClick;
  final Function(Document) onLongPress;
  // final VoidCallback onDelete;
  final bool isSelectionMode;
  final bool isSelected;

  const MoneyIncomeCard({
    Key? key,
    required this.document,
    required this.onClick,
    // required this.onDelete,
    required this.onLongPress,
    required this.isSelectionMode,
    required this.isSelected,
  }) : super(key: key);

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    double amountValue = amount is String ? double.tryParse(amount) ?? 0.0 : amount.toDouble();
    return NumberFormat('#,##0.00', 'ru_RU').format(amountValue);
  }

  String _getLocalizedStatus(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (document.deletedAt != null) {
      return localizations.translate('deleted') ?? 'Удален';
    }
    if (document.approved ?? false) {
      return localizations.translate('approved') ?? 'Проведен';
    } else {
      return localizations.translate('not_approved') ?? 'Не проведен';
    }
  }

  Color _getStatusColor() {
    if (document.deletedAt != null) {
      return Colors.red;
    }
    return document.approved == false ? Colors.orange : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => onClick(document),
      onLongPress: () => onLongPress(document),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFDDE8F5)
              : const Color(0xFFE9EDF5),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${localizations.translate('income') ?? 'Доход'} №${document.docNumber}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getLocalizedStatus(context),
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          /*if (!isSelectionMode && document.deletedAt == null) ...[const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => onDelete(),
                            child: Image.asset(
                              'assets/icons/delete.png',
                              width: 24,
                              height: 24,
                            ),
                          ),]*/
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${localizations.translate('amount') ?? 'Сумма'}: ${_formatAmount(document.amount)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                  ),

                  if (document.model?.name?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${localizations.translate('client') ?? 'Клиент'} ${document.model!.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                  ],

                  if (document.operationType == MoneyIncomeOperationType.send_another_cash_register.name) ...[
                    const SizedBox(height: 8),
                    Text(
                      localizations
                          .translate('sending_to_another_cash_register') // Отправка на другую кассу: {cashRegister}
                          .replaceAll('{cashRegister}', document.cashRegister?.name ?? '') ??
                          'Перевод в другую кассу ${document.cashRegister?.name ?? ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                    )
                  ],
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