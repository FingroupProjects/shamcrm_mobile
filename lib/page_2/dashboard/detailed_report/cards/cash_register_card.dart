import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';

import '../../../../models/page_2/dashboard/cash_balance_model.dart';

class CashRegisterCard extends StatelessWidget {
  final CashRegisters cashRegister;
  final Function(CashRegisters) onClick;
  final Function(CashRegisters) onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const CashRegisterCard({
    super.key,
    required this.cashRegister,
    required this.onClick,
    required this.onLongPress,
    required this.isSelectionMode,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final balance = cashRegister.balance ?? 0;
    final isPositive = balance >= 0;

    return GestureDetector(
      onTap: () => onClick(cashRegister),
      onLongPress: () => onLongPress(cashRegister),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.surfaceElevated.withValues(alpha: 0.98)
              : colors.surfacePrimary.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.borderPrimary : colors.borderSubtle,
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: context.appShadows.card,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cashRegister.name?.trim().isNotEmpty == true
                        ? cashRegister.name!
                        : localizations.translate('not_specified'),
                    style: textStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: localizations.translate('currency_label'),
                    value: cashRegister.currencyName?.trim().isNotEmpty == true
                        ? cashRegister.currencyName!
                        : localizations.translate('not_specified'),
                    valueColor: colors.textPrimary,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: localizations.translate('cash_balance'),
                    value: parseNumberToString(balance, nullValue: '0'),
                    valueColor: isPositive ? colors.success : colors.error,
                  ),
                ],
              ),
            ),
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: colors.textPrimary,
                  size: 24,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: colors.textMuted,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Row(
      children: [
        Text(
          '$label:',
          style: textStyles.bodySm.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: textStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
