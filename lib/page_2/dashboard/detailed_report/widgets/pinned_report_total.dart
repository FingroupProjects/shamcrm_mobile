import 'package:flutter/material.dart';

import '../../../../screens/profile/languages/app_localizations.dart';

class PinnedReportTotal extends StatelessWidget {
  final String total;
  final IconData icon;

  const PinnedReportTotal({
    super.key,
    required this.total,
    this.icon = Icons.summarize_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final totalLabel = AppLocalizations.of(context)!.translate('total').trim();
    final normalizedLabel =
        totalLabel.endsWith(':') ? totalLabel : '$totalLabel:';

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
      ),
    );
  }
}
