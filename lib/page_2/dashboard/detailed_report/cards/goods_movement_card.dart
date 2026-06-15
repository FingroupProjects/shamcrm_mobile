import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/good_variants_model.dart';

class GoodsMovementCard extends StatelessWidget {
  final GoodVariantItem variant;
  final Function(GoodVariantItem) onClick;
  final Function(GoodVariantItem) onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const GoodsMovementCard({
    Key? key,
    required this.variant,
    required this.onClick,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return GestureDetector(
      onTap: () => onClick(variant),
      onLongPress: () => onLongPress(variant),
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
            width: isSelected ? 2 : 1,
          ),
          boxShadow: context.appShadows.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                variant.fullName ?? variant.good?.name ?? 'Неизвестный товар',
                style: textStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelectionMode) ...[
              const SizedBox(width: 12),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: colors.textPrimary,
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
