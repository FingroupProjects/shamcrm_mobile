import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_colors.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_labels.dart';
import 'package:flutter/material.dart';

class SalesPlanProgressBar extends StatelessWidget {
  final double percent;
  final SalesPlanStatus status;
  final double height;
  final bool showLabel;
  final bool labelOnRight;
  final double? width;

  const SalesPlanProgressBar({
    super.key,
    required this.percent,
    required this.status,
    this.height = 8,
    this.showLabel = true,
    this.labelOnRight = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final fill = SalesPlanColors.progress(
      context,
      percent: percent,
      status: status,
    );
    final clamped = percent.clamp(0, 100).toDouble() / 100;
    final track = context.appColors.textSecondary.withValues(alpha: 0.22);

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        width: width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track),
            FractionallySizedBox(
              widthFactor: clamped,
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final label = Text(
      SalesPlanLabels.formatPercent(percent),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: fill,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    if (!showLabel) {
      return SizedBox(width: width, child: bar);
    }

    if (labelOnRight) {
      return Row(
        children: [
          Expanded(child: bar),
          const SizedBox(width: 10),
          label,
        ],
      );
    }

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar,
          const SizedBox(height: 5),
          label,
        ],
      ),
    );
  }
}
