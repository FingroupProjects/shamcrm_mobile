import 'package:crm_task_manager/page_2/money/money_income/money_income_operation_type.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/money/money_income_document_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import '../../../../bloc/page_2_BLOC/money_income/money_income_bloc.dart';
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
    double amountValue =
        amount is String ? double.tryParse(amount) ?? 0.0 : amount.toDouble();
    return NumberFormat('#,##0.00', 'ru_RU').format(amountValue);
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  String? _formatDocumentDate() {
    final rawDate = document.date ?? document.createdAt;
    if (rawDate == null || rawDate.isEmpty) return null;

    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(rawDate).toLocal());
    } catch (_) {
      return rawDate;
    }
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

  String _getDateLabel(AppLocalizations localizations) {
    final rawLabel = localizations.translate('date') ?? 'Дата';
    return rawLabel.trim().replaceFirst(RegExp(r':\s*$'), '');
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
    final formattedDate = _formatDocumentDate();

    return GestureDetector(
      onTap: () => onClick(document),
      onLongPress: () => onLongPress(document),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                  if (formattedDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_getDateLabel(localizations)}: $formattedDate',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                  ],
                  if ((document.exchangeRate?.value ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${localizations.translate('exchange_rate') ?? 'Курс валюты'}: ${document.exchangeRate!.value}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${localizations.translate('total_by_currency') ?? 'Итого валюты'}: ${_formatAmount(_parseDouble(document.amount) * _parseDouble(document.exchangeRate!.value))}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                  ],
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
                  if (document.operationType ==
                      MoneyIncomeOperationType
                          .send_another_cash_register.name) ...[
                    const SizedBox(height: 8),
                    Text(
                      localizations
                              .translate(
                                  'sending_to_another_cash_register') // Отправка на другую кассу: {cashRegister}
                              .replaceAll('{cashRegister}',
                                  document.cashRegister?.name ?? '') ??
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
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
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
