import 'package:flutter/material.dart';

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
  }) : assert(amount != null || amountText != null, 'Need amount or amountText');

  String _formatNumber(num value) {
    final s = value.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (m) => ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
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
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              amountText ?? _formatNumber(amount!),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
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
                              isUp ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 14,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                trendText!,
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: accentColor,
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
    );
  }
}