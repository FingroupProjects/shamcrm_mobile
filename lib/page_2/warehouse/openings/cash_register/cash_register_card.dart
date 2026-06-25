import 'package:crm_task_manager/models/page_2/openings/cash_register_openings_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../utils/global_fun.dart';

class CashRegisterCard extends StatelessWidget {
  final CashRegisterOpening cashRegister;
  final Function(CashRegisterOpening) onClick;
  final Function(CashRegisterOpening) onLongPress;
  final Function(CashRegisterOpening)? onDelete;
  final bool isSelectionMode;
  final bool isSelected;

  const CashRegisterCard({
    Key? key,
    required this.cashRegister,
    required this.onClick,
    required this.onLongPress,
    this.onDelete,
    this.isSelectionMode = false,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return GestureDetector(
      onTap: () => onClick(cashRegister),
      onLongPress: () => onLongPress(cashRegister),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colors.fieldBg : colors.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localizations.translate('title_with_two_dots')}${cashRegister.cashRegister?.name ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Баланс: ${parseNumberToString(cashRegister.sum ?? '0')}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            if (onDelete != null)
              GestureDetector(
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 24,
                  color: colors.buttonDangerBg,
                ),
                onTap: () => onDelete!(cashRegister),
              ),
            if (isSelectionMode) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: colors.buttonPrimaryBg,
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
