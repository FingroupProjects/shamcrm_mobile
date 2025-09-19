import 'package:crm_task_manager/page_2/money/money_outcome/operation_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/models/money/money_outcome_document_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/page_2/money/money_outcome/widgets/money_outcome_deletion.dart';
import 'package:crm_task_manager/bloc/money_outcome/money_outcome_bloc.dart';
import 'package:intl/intl.dart';

class MoneyOutcomeCard extends StatelessWidget {
  final Document document;
  final Function(Document)? onUpdate;
  final Function(int)? onDelete;

  const MoneyOutcomeCard({
    Key? key,
    required this.document,
    this.onUpdate,
    this.onDelete,
  }) : super(key: key);

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    double amountValue = amount is String ? double.tryParse(amount) ?? 0.0 : amount.toDouble();
    return NumberFormat('#,##0.00', 'ru_RU').format(amountValue);
  }

  String _getLocalizedStatus(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (document.approved ?? false) {
      return localizations.translate('approved') ?? 'Проведен';
    } else {
      return localizations.translate('not_approved') ?? 'Не проведен';
    }
  }

  Color _getStatusColor() {
    return document.approved == false ? Colors.orange: Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        if (onUpdate != null) onUpdate!(document);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EDF5),
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
                    '${localizations.translate('outcome') ?? 'Расход'} №${document.docNumber}',
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
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showDeleteDialog(context),
                        child: Image.asset(
                          'assets/icons/delete.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ],
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
            if (document.model != null && document.model!.name != null && document.model!.name!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${localizations.translate('client') ?? 'Клиент'}: ${document.model!.name}',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w400,
                  color: Color(0xff99A4BA),
                ),
              ),
            ],
            if (document.operationType != null && document.operationType == OperationType.receive_another_cash_register.name) ...[
              const SizedBox(height: 8),
                Text(
                  'Получение с другой кассы: ${document.cashRegister?.name}',
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
    );
  }

  void _showDeleteDialog(BuildContext context) {
    if (document.id != null && onDelete != null) {
      showDialog(
        context: context,
        builder: (_) => BlocProvider.value(
          value: context.read<MoneyOutcomeBloc>(), // reuse the same instance
          child: MoneyOutcomeDeleteDialog(documentId: document.id!),
        ),
      ).then((result) {
        if (result == true) {
          onDelete!(document.id!);
        }
      });
    }
  }
}