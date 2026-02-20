import 'package:flutter/material.dart';

/// Helper class for responsive design calculations.
/// Uses percentage of screen width for smooth font scaling across all devices.
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
      isTablet ? 20.0 : (isSmallPhone ? 10.0 : 14.0);
  double get verticalPadding => isTablet ? 20.0 : (isSmallPhone ? 10.0 : 14.0);
  double get cardPadding => isTablet ? 18.0 : (isSmallPhone ? 10.0 : 14.0);

  // Adaptive spacing
  double get spacing => isTablet ? 16.0 : (isSmallPhone ? 10.0 : 12.0);
  double get smallSpacing => isTablet ? 10.0 : (isSmallPhone ? 4.0 : 6.0);
  double get largeSpacing => isTablet ? 24.0 : (isSmallPhone ? 16.0 : 20.0);

  // Adaptive border radius
  double get borderRadius => isTablet ? 18.0 : (isSmallPhone ? 10.0 : 14.0);
  double get smallBorderRadius => isTablet ? 10.0 : (isSmallPhone ? 6.0 : 8.0);

  // ─── Adaptive font sizes (percentage of screen width with clamp) ───
  // heroFontSize:     ~28 on large → ~20 on small (for big hero numbers)
  double get heroFontSize => (screenWidth * 0.06).clamp(20.0, 32.0);

  // largeFontSize:    ~18 on large → ~14 on small (for stat summary values)
  double get largeFontSize => (screenWidth * 0.04).clamp(14.0, 22.0);

  // titleFontSize:    ~16 on large → ~13 on small (chart titles)
  double get titleFontSize => (screenWidth * 0.038).clamp(13.0, 18.0);

  // subtitleFontSize: ~14 on large → ~12 on small
  double get subtitleFontSize => (screenWidth * 0.034).clamp(12.0, 16.0);

  // bodyFontSize:     ~13 on large → ~11 on small
  double get bodyFontSize => (screenWidth * 0.030).clamp(11.0, 14.0);

  // captionFontSize:  ~12 on large → ~10 on small
  double get captionFontSize => (screenWidth * 0.028).clamp(10.0, 13.0);

  // smallFontSize:    ~11 on large → ~9 on small
  double get smallFontSize => (screenWidth * 0.025).clamp(9.0, 12.0);

  // xSmallFontSize:   ~10 on large → ~8 on small
  double get xSmallFontSize => (screenWidth * 0.022).clamp(8.0, 11.0);

  // Chart specific heights
  double get chartHeight => isTablet ? 300.0 : (isSmallPhone ? 220.0 : 260.0);
  double get smallChartHeight =>
      isTablet ? 240.0 : (isSmallPhone ? 180.0 : 220.0);

  // Icon sizes
  double get iconSize => isTablet ? 24.0 : (isSmallPhone ? 18.0 : 20.0);
  double get smallIconSize => isTablet ? 18.0 : (isSmallPhone ? 14.0 : 16.0);
}
