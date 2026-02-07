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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 360;
    final isTablet = screenWidth > 600;

    // Adaptive sizes
    final padding = isTablet ? 24.0 : (isSmallPhone ? 14.0 : 20.0);
    final iconSize = isTablet ? 56.0 : (isSmallPhone ? 40.0 : 48.0);
    final iconInnerSize = isTablet ? 28.0 : (isSmallPhone ? 20.0 : 24.0);
    final valueFontSize = isTablet ? 32.0 : (isSmallPhone ? 22.0 : 28.0);
    final titleFontSize = isTablet ? 15.0 : (isSmallPhone ? 12.0 : 14.0);
    final changeFontSize = isTablet ? 13.0 : (isSmallPhone ? 11.0 : 12.0);
    final borderRadius = isTablet ? 20.0 : (isSmallPhone ? 12.0 : 16.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              height: isSmallPhone ? 3 : 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconColor, iconColor.withOpacity(0.6)],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [iconColor, iconColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(iconSize / 4),
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: iconInnerSize,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallPhone ? 8 : 16),
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
                      SizedBox(height: isSmallPhone ? 2 : 4),
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
                SizedBox(height: isSmallPhone ? 8 : 12),
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: changeFontSize + 2,
                      color: isPositive
                          ? const Color(0xff10B981)
                          : const Color(0xffEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
