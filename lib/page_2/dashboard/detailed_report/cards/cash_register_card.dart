import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../../../models/page_2/dashboard/cash_balance_model.dart';

class CashRegisterCard extends StatelessWidget {
  final CashRegisters cashRegister;
  final Function(CashRegisters) onClick;
  final Function(CashRegisters) onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const CashRegisterCard({
    Key? key,
    required this.cashRegister,
    required this.onClick,
    required this.onLongPress,
    required this.isSelectionMode,
    required this.isSelected,
  }) : super(key: key);

  String _formatAmount(int? amount) {
    double amountValue = (amount ?? 0).toDouble();
    return NumberFormat('#,##0.00', 'ru_RU').format(amountValue);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Не обновлялось';
    
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy HH:mm', 'ru_RU').format(date);
    } catch (e) {
      return 'Неверная дата';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => onClick(cashRegister),
      onLongPress: () => onLongPress(cashRegister),
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
                    '${localizations.translate('cash_register_name') ?? 'Название кассы'}: ${cashRegister.name ?? 'Не указано'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${localizations.translate('cash_balance') ?? 'Остаток кассы'}:',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatAmount(cashRegister.balance),
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: (cashRegister.balance ?? 0) >= 0
                              ? const Color(0xff10B981)
                              : const Color(0xffEF4444),
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
