import 'package:flutter/material.dart';

import '../../../../core/theme/helpers/theme_context_extension.dart';
import '../../../../models/page_2/openings/supplier_openings_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../utils/global_fun.dart';

class SupplierCard extends StatelessWidget {
  final SupplierOpening supplier;
  final Function(SupplierOpening) onClick;
  final Function(SupplierOpening) onLongPress;
  final Function(SupplierOpening)? onDelete;
  final bool isSelectionMode;
  final bool isSelected;

  const SupplierCard({
    Key? key,
    required this.supplier,
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
      onTap: () => onClick(supplier),
      onLongPress: () => onLongPress(supplier),
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
                    '${localizations.translate('title_with_two_dots')}${supplier.counterparty?.name ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Наш долг: ${parseNumberToString(supplier.ourDuty ?? '0')}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Долг поставщика: ${parseNumberToString(supplier.debtToUs ?? '0')}',
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
                onTap: () => onDelete!(supplier),
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
