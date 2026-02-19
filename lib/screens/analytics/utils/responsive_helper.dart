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

  // ─── Adaptive font sizes (percentage of screen width with clamp) ───
  // heroFontSize:     ~34-38 on large → ~26-28 on small (for big numbers)
  double get heroFontSize => (screenWidth * 0.084).clamp(26.0, 40.0);

  // largeFontSize:    ~20-24 on large → ~18 on small
  double get largeFontSize => (screenWidth * 0.05).clamp(18.0, 28.0);

  // titleFontSize:    ~18 on large → ~15 on small
  double get titleFontSize => (screenWidth * 0.042).clamp(14.0, 22.0);

  // subtitleFontSize: ~16 on large → ~14 on small
  double get subtitleFontSize => (screenWidth * 0.038).clamp(13.0, 18.0);

  // bodyFontSize:     ~14 on large → ~12 on small
  double get bodyFontSize => (screenWidth * 0.033).clamp(11.0, 16.0);

  // captionFontSize:  ~13 on large → ~11 on small
  double get captionFontSize => (screenWidth * 0.031).clamp(10.0, 15.0);

  // smallFontSize:    ~12 on large → ~10 on small
  double get smallFontSize => (screenWidth * 0.028).clamp(9.0, 14.0);

  // xSmallFontSize:   ~10-11 on large → ~9 on small
  double get xSmallFontSize => (screenWidth * 0.025).clamp(8.0, 13.0);

  // Chart specific heights
  double get chartHeight => isTablet ? 350.0 : (isSmallPhone ? 250.0 : 300.0);
  double get smallChartHeight =>
      isTablet ? 280.0 : (isSmallPhone ? 200.0 : 250.0);

  // Icon sizes
  double get iconSize => isTablet ? 28.0 : (isSmallPhone ? 20.0 : 24.0);
  double get smallIconSize => isTablet ? 20.0 : (isSmallPhone ? 16.0 : 18.0);
}
