import 'package:flutter/material.dart';

/// Helper class for responsive design calculations
class ResponsiveHelper {
  final BuildContext context;

  ResponsiveHelper(this.context);

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

  bool get isSmallPhone => screenWidth < 360;
  bool get isMediumPhone => screenWidth >= 360 && screenWidth < 400;
  bool get isLargePhone => screenWidth >= 400 && screenWidth < 600;
  bool get isTablet => screenWidth >= 600;

  // Adaptive padding
  double get horizontalPadding =>
      isTablet ? 24.0 : (isSmallPhone ? 12.0 : 16.0);
  double get verticalPadding => isTablet ? 24.0 : (isSmallPhone ? 12.0 : 16.0);
  double get cardPadding => isTablet ? 24.0 : (isSmallPhone ? 14.0 : 20.0);

  // Adaptive spacing
  double get spacing => isTablet ? 20.0 : (isSmallPhone ? 12.0 : 16.0);
  double get smallSpacing => isTablet ? 12.0 : (isSmallPhone ? 6.0 : 8.0);
  double get largeSpacing => isTablet ? 32.0 : (isSmallPhone ? 20.0 : 24.0);

  // Adaptive border radius
  double get borderRadius => isTablet ? 20.0 : (isSmallPhone ? 12.0 : 16.0);
  double get smallBorderRadius => isTablet ? 12.0 : (isSmallPhone ? 8.0 : 10.0);

  // Adaptive font sizes
  double get titleFontSize => isTablet ? 22.0 : (isSmallPhone ? 16.0 : 18.0);
  double get bodyFontSize => isTablet ? 16.0 : (isSmallPhone ? 13.0 : 14.0);
  double get smallFontSize => isTablet ? 14.0 : (isSmallPhone ? 11.0 : 12.0);
  double get largeFontSize => isTablet ? 28.0 : (isSmallPhone ? 20.0 : 24.0);

  // Chart specific heights
  double get chartHeight => isTablet ? 350.0 : (isSmallPhone ? 250.0 : 300.0);
  double get smallChartHeight =>
      isTablet ? 280.0 : (isSmallPhone ? 200.0 : 250.0);

  // Icon sizes
  double get iconSize => isTablet ? 28.0 : (isSmallPhone ? 20.0 : 24.0);
  double get smallIconSize => isTablet ? 20.0 : (isSmallPhone ? 16.0 : 18.0);
}
