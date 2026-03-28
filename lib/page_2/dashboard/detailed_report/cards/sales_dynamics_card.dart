import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/page_2/dashboard/sales_model.dart';
import 'package:intl/intl.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class SalesDynamicsCard extends StatelessWidget {
  final MonthData monthData;

  const SalesDynamicsCard({
    Key? key,
    required this.monthData,
  }) : super(key: key);

  String _formatAmount(String amount) {
    double amountValue = double.tryParse(amount.replaceAll(' ', '')) ?? 0.0;
    return NumberFormat('#,##0.00', 'ru_RU').format(amountValue);
  }

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
                  '${localizations.translate('month') ?? 'Месяц'}: ${monthData.monthName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff1E2E52),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${localizations.translate('total_amount') ?? 'Общая сумма'}: ${_formatAmount(monthData.totalAmount)}',
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