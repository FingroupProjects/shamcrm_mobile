import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/dashboard/goods_expiration_report.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

/// Карточка товара по сроку годности.
/// Без перехода внутрь — только просмотр в списке.
class GoodsExpirationCard extends StatelessWidget {
  final GoodsExpirationItem item;

  const GoodsExpirationCard({super.key, required this.item});

  Color _daysColor(BuildContext context) {
    final colors = context.appColors;
    if (item.daysLeft < 0) return colors.error;
    if (item.daysLeft == 0) return colors.warning;
    return colors.success;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final quantityText = item.unit.isEmpty
        ? item.quantity
        : '${item.quantity} ${item.unit}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: textStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${localizations.translate('category_details')}: ${item.category}',
            style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
          ),
          if (item.storage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${localizations.translate('storages')}: ${item.storage}',
              style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${localizations.translate('goods_expiration_date')}: ${item.formattedExpirationDate}',
            style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '${localizations.translate('goods_days_left')}: ${item.daysLeftLabel} ${localizations.translate('goods_days_short')}',
            style: textStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: _daysColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${localizations.translate('quantity')}: $quantityText',
            style: textStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
