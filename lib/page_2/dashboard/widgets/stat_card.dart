import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

class StatCard extends StatelessWidget {
  final Color accentColor;
  final String title;
  final Widget? leading;
  final num? amount;
  final String? amountText;
  final bool showCurrencySymbol;
  final String currencySymbol;
  final bool isUp;
  final String? trendText;
  final VoidCallback onTap;

  const StatCard({
    super.key,
    required this.accentColor,
    required this.title,
    this.leading,
    this.amount,
    this.amountText,
    this.showCurrencySymbol = false,
    this.currencySymbol = '₽',
    this.isUp = true,
    this.trendText,
    required this.onTap,
  }) : assert(
            amount != null || amountText != null, 'Need amount or amountText');

  String _formatNumber(num value) {
    // Конвертируем в строку
    String s = value.toString();

    // Удаляем незначащие нули после точки (например, 10.0 -> 10, 10.00 -> 10)
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'\.0+$'), ''); // удаляем .0, .00, .000 и т.д.
    }

    // Добавляем пробелы между тысячами
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (m) => ' ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfacePrimary.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: context.appShadows.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Colored accent bar
                Container(
                  width: 5,
                  color: accentColor,
                ),
                // Content area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row with Icon
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (leading != null) ...[
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: leading!,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                title,
                                style: textStyles.bodySm.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colors.textSecondary,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Amount Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            if (showCurrencySymbol) ...[
                              Text(
                                currencySymbol,
                                style: textStyles.titleMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                amountText ?? _formatNumber(amount!),
                                style: textStyles.titleMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Trend Row
                        if (trendText != null)
                          Row(
                            children: [
                              Icon(
                                isUp
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 14,
                                color: isUp ? colors.success : colors.error,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  trendText!,
                                  style: textStyles.bodySm.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: isUp ? colors.success : colors.error,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
