import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

import 'package:crm_task_manager/screens/analytics/utils/analytics_localization.dart';

class ChartEmptyOverlay extends StatelessWidget {
  final bool show;
  final Widget child;
  final String? label;

  const ChartEmptyOverlay({
    super.key,
    required this.show,
    required this.child,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Stack(
      children: [
        Positioned.fill(child: child),
        if (show)
          Positioned.fill(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surfacePrimary.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.borderSubtle.withValues(alpha: 0.34),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  label ??
                      analyticsText(
                        context,
                        'no_data_to_display',
                        fallback: 'No data',
                      ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                    fontFamily: 'Golos',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
