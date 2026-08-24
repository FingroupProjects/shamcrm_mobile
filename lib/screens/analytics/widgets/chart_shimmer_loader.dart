import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/shimmer_wave.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Internal constants
// ─────────────────────────────────────────────────────────────────────────────

const List<double> _barHeights = [
  0.38, 0.62, 0.48, 0.78, 0.55,
  0.70, 0.42, 0.86, 0.58, 0.66,
  0.50, 0.74,
];

// ─────────────────────────────────────────────────────────────────────────────
// Theme-adaptive ShimmerWave wrapper — same colour strategy as NavBarShimmer
// ─────────────────────────────────────────────────────────────────────────────

ShimmerWave _navStyleShimmer({
  required BuildContext context,
  required Widget child,
}) {
  final colors = context.appColors;
  return ShimmerWave(
    duration: const Duration(milliseconds: 1600),
    colors: [
      colors.surfacePrimary.withValues(alpha: 0.55),
      colors.backgroundSecondary.withValues(alpha: 0.88),
      colors.surfaceAccent.withValues(alpha: 0.30),
      colors.surfacePrimary.withValues(alpha: 0.95),
      colors.surfacePrimary.withValues(alpha: 0.55),
    ],
    stops: const [0.0, 0.30, 0.52, 0.70, 1.0],
    child: child,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Bar chart area (used inside a loading chart card)
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsChartShimmerLoader extends StatelessWidget {
  const AnalyticsChartShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // borderSubtle is always contrasted against surfacePrimary in any theme
    final barColor = colors.borderSubtle;

    return _navStyleShimmer(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 20, 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxH = constraints.maxHeight - 0;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _barHeights.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: (maxH * _barHeights[i]).clamp(4.0, maxH),
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer skeleton
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsChartFooterSkeleton extends StatelessWidget {
  final double padding;

  const AnalyticsChartFooterSkeleton({
    super.key,
    this.padding = 14,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final blockColor = colors.borderSubtle;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: _navStyleShimmer(
        context: context,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FooterBlock(color: blockColor),
            _FooterBlock(color: blockColor, alignEnd: true),
          ],
        ),
      ),
    );
  }
}

class _FooterBlock extends StatelessWidget {
  final Color color;
  final bool alignEnd;

  const _FooterBlock({required this.color, this.alignEnd = false});

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

// ─────────────────────────────────────────────────────────────────────────────
// Full-card skeleton (header + bars + footer)
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsFullCardSkeleton extends StatelessWidget {
  const AnalyticsFullCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final responsive = ResponsiveHelper(context);
    final itemColor = colors.borderSubtle;
    final chartHeight = responsive.chartHeight;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _navStyleShimmer(
        context: context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(responsive.cardPadding),
              child: Row(
                children: [
                  Container(
                    width: responsive.iconSize,
                    height: responsive.iconSize,
                    decoration: BoxDecoration(
                      color: itemColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(width: responsive.smallSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 13,
                          decoration: BoxDecoration(
                            color: itemColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 9,
                          width: 90,
                          decoration: BoxDecoration(
                            color: itemColor.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: itemColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bar-chart area ──────────────────────────────────────────────
            SizedBox(
              height: chartHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 22, 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxH = constraints.maxHeight;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < _barHeights.length; i++) ...[
                          if (i > 0) const SizedBox(width: 5),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: (maxH * _barHeights[i]).clamp(4.0, maxH),
                                decoration: BoxDecoration(
                                  color: itemColor,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── Footer ─────────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(responsive.cardPadding),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FooterBlock(color: itemColor),
                  _FooterBlock(color: itemColor, alignEnd: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats card skeleton (2×2 grid)
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsStatCardSkeleton extends StatelessWidget {
  const AnalyticsStatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final itemColor = colors.borderSubtle;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _navStyleShimmer(
        context: context,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: itemColor,
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              Container(
                height: 22,
                width: 70,
                decoration: BoxDecoration(
                  color: itemColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: itemColor.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
