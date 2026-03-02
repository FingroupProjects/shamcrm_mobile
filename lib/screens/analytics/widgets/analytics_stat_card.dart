import 'package:flutter/material.dart';

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: const Color(0xffE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                        color: Colors.white,
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
                                color: const Color(0xff0F172A),
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
                              color: const Color(0xff64748B),
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
                          color: isPositive
                              ? const Color(0xff10B981)
                              : const Color(0xffEF4444),
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
                                color: isPositive
                                    ? const Color(0xff10B981)
                                    : const Color(0xffEF4444),
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
