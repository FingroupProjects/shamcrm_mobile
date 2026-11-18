import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PinnedOrderPaymentTotal extends StatelessWidget {
  final String periodLabel;
  final double? total;

  const PinnedOrderPaymentTotal({
    super.key,
    required this.periodLabel,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final formattedTotal = total == null
        ? null
        : NumberFormat('#,##0.00', 'ru_RU').format(total);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.buttonPrimaryBg.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.payments_outlined,
              size: 18,
              color: colors.buttonPrimaryBg,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              periodLabel.endsWith(':') ? periodLabel : '$periodLabel:',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyles.bodyMd.copyWith(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (formattedTotal == null)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.buttonPrimaryBg,
              ),
            )
          else
            Text(
              formattedTotal,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: textStyles.titleMd.copyWith(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
