import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/shimmer_wave.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

/// Skeleton loader for charts while data is loading.
/// Uses the same shimmer wave animation as CRM analytics charts.
class ChartSkeleton extends StatelessWidget {
  final double height;
  final String title;

  const ChartSkeleton({
    super.key,
    this.height = 300,
    this.title = '',
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: context.appShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: textStyles.bodyLg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            if (title.isNotEmpty) const SizedBox(height: 16),
            const Expanded(
              child: ShimmerWave(
                child: _ChartBarsSkeleton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartBarsSkeleton extends StatelessWidget {
  const _ChartBarsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: const [
        _Bar(heightFactor: 0.35),
        SizedBox(width: 10),
        _Bar(heightFactor: 0.65),
        SizedBox(width: 10),
        _Bar(heightFactor: 0.45),
        SizedBox(width: 10),
        _Bar(heightFactor: 0.8),
        SizedBox(width: 10),
        _Bar(heightFactor: 0.55),
        SizedBox(width: 10),
        _Bar(heightFactor: 0.7),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double heightFactor;

  const _Bar({required this.heightFactor});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Use a slightly darker tint than the card surface so shimmer bars are
    // clearly visible in both light and dark mode.
    final barColor = colors.textSecondary.withValues(alpha: 0.13);
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: heightFactor,
          child: Container(
            width: 18,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple skeleton for smaller widgets
class SimpleSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SimpleSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.textSecondary.withValues(alpha: 0.10),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}
