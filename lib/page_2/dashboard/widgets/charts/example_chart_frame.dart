import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

/// Пример графика, как в CRM: фигура остаётся, сверху подпись «нет данных».
class ExampleChartFrame extends StatelessWidget {
  const ExampleChartFrame({
    super.key,
    required this.show,
    required this.label,
    required this.child,
  });

  final bool show;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        if (show)
          IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                  fontFamily: 'Gilroy',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
