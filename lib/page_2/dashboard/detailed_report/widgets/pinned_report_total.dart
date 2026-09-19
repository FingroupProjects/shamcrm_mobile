import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

import '../../../../screens/profile/languages/app_localizations.dart';

class PinnedReportCurrencyTotal {
  final String currency;
  final String total;

  const PinnedReportCurrencyTotal({
    required this.currency,
    required this.total,
  });
}

class PinnedReportTotal extends StatelessWidget {
  final String total;
  final IconData icon;
  final List<PinnedReportCurrencyTotal> currencyTotals;
  final bool showPrimaryTotal;

  const PinnedReportTotal({
    super.key,
    required this.total,
    this.icon = Icons.summarize_outlined,
    this.currencyTotals = const [],
    this.showPrimaryTotal = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final totalLabel = AppLocalizations.of(context)!.translate('total').trim();
    final normalizedLabel =
        totalLabel.endsWith(':') ? totalLabel : '$totalLabel:';
    final visibleCurrencyTotals = currencyTotals
        .where((item) => item.total.trim().isNotEmpty)
        .toList(growable: false);
    final displayedCurrencyTotals = !showPrimaryTotal &&
            visibleCurrencyTotals.isEmpty &&
            total.trim().isNotEmpty
        ? [PinnedReportCurrencyTotal(currency: '', total: total)]
        : visibleCurrencyTotals;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colors.borderSubtle,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.textPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: colors.iconPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showPrimaryTotal)
                    _TotalLine(
                      label: normalizedLabel,
                      value: total,
                    ),
                  if (showPrimaryTotal && displayedCurrencyTotals.isNotEmpty)
                    const SizedBox(height: 8),
                  ...displayedCurrencyTotals.asMap().entries.map((entry) {
                    final item = entry.value;
                    final currency = item.currency.trim();
                    return Padding(
                      padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 8),
                      child: _TotalLine(
                        label: currency.isEmpty ? normalizedLabel : '$currency:',
                        value: item.total,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Подпись слева, сумма справа — без пустого места в середине.
class _TotalLine extends StatelessWidget {
  final String label;
  final String value;

  const _TotalLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
