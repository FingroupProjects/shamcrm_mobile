import 'package:crm_task_manager/models/page_2/dashboard/creditors_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return GestureDetector(
      onTap: () => onClick(creditor),
      onLongPress: () => onLongPress(creditor),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localizations.translate('client')} ${creditor.name}',
                    style: textStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w400,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('debt_amount')}: ${parseNumberToString(creditor.debtAmount)}',
                    style: textStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
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
                  color: colors.textPrimary,
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
