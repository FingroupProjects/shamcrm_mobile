import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

class AnalyticsStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color iconColor;

  const AnalyticsStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isVeryCompact = w < 140;
        final isCompact = w < 180;

        final padding = isVeryCompact ? 10.0 : (isCompact ? 12.0 : 14.0);
        final iconSize = isVeryCompact ? 28.0 : (isCompact ? 32.0 : 36.0);
        final iconInnerSize = isVeryCompact ? 14.0 : (isCompact ? 16.0 : 18.0);
        final valueFontSize = isVeryCompact ? 18.0 : (isCompact ? 20.0 : 22.0);
        final titleFontSize = isVeryCompact ? 10.0 : (isCompact ? 11.0 : 12.0);
        final changeFontSize = isVeryCompact ? 9.0 : (isCompact ? 10.0 : 11.0);
        final borderRadius = isVeryCompact ? 10.0 : (isCompact ? 12.0 : 14.0);

        return Container(
          decoration: BoxDecoration(
            color: colors.surfacePrimary.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: colors.borderSubtle.withValues(alpha: 0.32),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Gradient top border
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor, iconColor.withValues(alpha: 0.6)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      topRight: Radius.circular(borderRadius),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [iconColor, iconColor.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(iconSize / 4),
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: colors.textInverse,
                        size: iconInnerSize,
                      ),
                    ),
                    SizedBox(height: isVeryCompact ? 6 : 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: valueFontSize,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                                fontFamily: 'Golos',
                              ),
                            ),
                          ),
                          SizedBox(height: isVeryCompact ? 1 : 2),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              color: colors.textSecondary,
                              fontFamily: 'Golos',
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isVeryCompact ? 4 : 6),
                    Row(
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: changeFontSize + 2,
                          color: isPositive ? colors.success : colors.error,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              change,
                              style: TextStyle(
                                fontSize: changeFontSize,
                                fontWeight: FontWeight.w600,
                                color:
                                    isPositive ? colors.success : colors.error,
                                fontFamily: 'Golos',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
