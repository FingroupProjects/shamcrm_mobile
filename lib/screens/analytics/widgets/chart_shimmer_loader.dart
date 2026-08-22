import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/shimmer_wave.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

class AnalyticsChartShimmerLoader extends StatelessWidget {
  const AnalyticsChartShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final shimmerColor =
        context.appColors.surfaceElevated.withValues(alpha: 0.92);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 20, 20),
      child: ShimmerWave(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _barHeights.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _Bar(heightFactor: _barHeights[i], color: shimmerColor),
            ],
          ],
        ),
      ),
    );
  }
}

const List<double> _barHeights = [
  0.38,
  0.62,
  0.48,
  0.78,
  0.55,
  0.70,
  0.42,
  0.86,
  0.58,
  0.66,
  0.50,
  0.74,
];

class _Bar extends StatelessWidget {
  final double heightFactor;
  final Color color;

  const _Bar({required this.heightFactor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: heightFactor,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class AnalyticsChartFooterSkeleton extends StatelessWidget {
  final double padding;

  const AnalyticsChartFooterSkeleton({
    super.key,
    this.padding = 14,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final shimmerColor = colors.surfaceElevated.withValues(alpha: 0.92);
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.borderSubtle),
        ),
      ),
      child: ShimmerWave(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FooterBlock(color: shimmerColor),
            _FooterBlock(color: shimmerColor, alignEnd: true),
          ],
        ),
      ),
    );
  }
}

class _FooterBlock extends StatelessWidget {
  final Color color;
  final bool alignEnd;

  const _FooterBlock({
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          height: 10,
          width: 88,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 18,
          width: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}
