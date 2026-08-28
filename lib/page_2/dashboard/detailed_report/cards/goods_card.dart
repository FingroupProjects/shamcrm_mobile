import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

import '../../../../models/page_2/dashboard/dashboard_goods_report.dart';

class GoodsCard extends StatelessWidget {
  final DashboardGoods goods;
  final Function(DashboardGoods) onClick;
  final Function(DashboardGoods) onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const GoodsCard({
    super.key,
    required this.goods,
    required this.onClick,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return GestureDetector(
      onTap: () => onClick(goods),
      onLongPress: () => onLongPress(goods),
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
                    '${localizations.translate('goods_name_details')}: ${goods.name}',
                    style: textStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w400,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('category_details')}: ${goods.category}',
                    style: textStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('storages')}: ${goods.storages.map((s) => '${s.name}(${s.quantity})').join(', ')}',
                    style: textStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w400,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localizations.translate('quantity')}: ${goods.totalQuantity}',
                    style: textStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Сумма: ${goods.totalSum}',
                    style: textStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
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
