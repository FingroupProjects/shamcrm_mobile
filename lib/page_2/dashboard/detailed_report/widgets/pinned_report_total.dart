import 'package:flutter/material.dart';

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xffDDE5F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff1E2E52).withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xff1E2E52).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xff1E2E52),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showPrimaryTotal) ...[
                    Row(
                      children: [
                        Text(
                          normalizedLabel,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff64748B),
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
                                total,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff1E2E52),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (displayedCurrencyTotals.isNotEmpty)
                      const SizedBox(height: 10),
                  ],
                  if (displayedCurrencyTotals.isNotEmpty)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth < 270 ? 1 : 2;
                        final tileWidth =
                            (constraints.maxWidth - ((columns - 1) * 8)) /
                                columns;

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: displayedCurrencyTotals.map((item) {
                            return SizedBox(
                              width: tileWidth,
                              child: _CurrencyTotalTile(item: item),
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyTotalTile extends StatelessWidget {
  final PinnedReportCurrencyTotal item;

  const _CurrencyTotalTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final currency = item.currency.trim();
    final text =
        currency.isEmpty ? 'Итого: ${item.total}' : '${item.total} $currency';

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xffF6F8FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xffDDE5F0),
          width: 1,
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xff1E2E52),
        ),
      ),
    );
  }
}
