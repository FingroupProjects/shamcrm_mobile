import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.appBackground,
    required this.screenBackground,
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.surfaceElevated,
    required this.surfaceInteractive,
    required this.surfaceInverse,
    required this.surfaceDangerSubtle,
    required this.surfaceWarningSubtle,
    required this.surfaceSuccessSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.textBrand,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.iconInverse,
    required this.iconBrand,
    required this.borderPrimary,
    required this.borderSecondary,
    required this.borderFocused,
    required this.dividerPrimary,
    required this.dividerSubtle,
    required this.buttonPrimaryBackground,
    required this.buttonPrimaryForeground,
    required this.buttonSecondaryBackground,
    required this.buttonSecondaryForeground,
    required this.buttonTertiaryForeground,
    required this.buttonDangerBackground,
    required this.buttonDangerForeground,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputFocusedBorder,
    required this.inputErrorBorder,
    required this.selectionBackground,
    required this.selectionForeground,
    required this.toggleActive,
    required this.toggleInactive,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.archived,
    required this.scrim,
    required this.dialogBackground,
    required this.bottomSheetBackground,
    required this.snackSuccessBackground,
    required this.snackErrorBackground,
    required this.tooltipBackground,
    required this.shadowColor,
  });

  final Color appBackground;
  final Color screenBackground;
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color surfaceElevated;
  final Color surfaceInteractive;
  final Color surfaceInverse;
  final Color surfaceDangerSubtle;
  final Color surfaceWarningSubtle;
  final Color surfaceSuccessSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;
  final Color textBrand;
  final Color iconPrimary;
  final Color iconSecondary;
  final Color iconInverse;
  final Color iconBrand;
  final Color borderPrimary;
  final Color borderSecondary;
  final Color borderFocused;
  final Color dividerPrimary;
  final Color dividerSubtle;
  final Color buttonPrimaryBackground;
  final Color buttonPrimaryForeground;
  final Color buttonSecondaryBackground;
  final Color buttonSecondaryForeground;
  final Color buttonTertiaryForeground;
  final Color buttonDangerBackground;
  final Color buttonDangerForeground;
  final Color inputBackground;
  final Color inputBorder;
  final Color inputFocusedBorder;
  final Color inputErrorBorder;
  final Color selectionBackground;
  final Color selectionForeground;
  final Color toggleActive;
  final Color toggleInactive;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color pending;
  final Color approved;
  final Color rejected;
  final Color archived;
  final Color scrim;
  final Color dialogBackground;
  final Color bottomSheetBackground;
  final Color snackSuccessBackground;
  final Color snackErrorBackground;
  final Color tooltipBackground;
  final Color shadowColor;

  @override
  AppThemeColors copyWith({
    Color? appBackground,
    Color? screenBackground,
    Color? surfacePrimary,
    Color? surfaceSecondary,
    Color? surfaceElevated,
    Color? surfaceInteractive,
    Color? surfaceInverse,
    Color? surfaceDangerSubtle,
    Color? surfaceWarningSubtle,
    Color? surfaceSuccessSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? textBrand,
    Color? iconPrimary,
    Color? iconSecondary,
    Color? iconInverse,
    Color? iconBrand,
    Color? borderPrimary,
    Color? borderSecondary,
    Color? borderFocused,
    Color? dividerPrimary,
    Color? dividerSubtle,
    Color? buttonPrimaryBackground,
    Color? buttonPrimaryForeground,
    Color? buttonSecondaryBackground,
    Color? buttonSecondaryForeground,
    Color? buttonTertiaryForeground,
    Color? buttonDangerBackground,
    Color? buttonDangerForeground,
    Color? inputBackground,
    Color? inputBorder,
    Color? inputFocusedBorder,
    Color? inputErrorBorder,
    Color? selectionBackground,
    Color? selectionForeground,
    Color? toggleActive,
    Color? toggleInactive,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? pending,
    Color? approved,
    Color? rejected,
    Color? archived,
    Color? scrim,
    Color? dialogBackground,
    Color? bottomSheetBackground,
    Color? snackSuccessBackground,
    Color? snackErrorBackground,
    Color? tooltipBackground,
    Color? shadowColor,
  }) {
    return AppThemeColors(
      appBackground: appBackground ?? this.appBackground,
      screenBackground: screenBackground ?? this.screenBackground,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceInteractive: surfaceInteractive ?? this.surfaceInteractive,
      surfaceInverse: surfaceInverse ?? this.surfaceInverse,
      surfaceDangerSubtle: surfaceDangerSubtle ?? this.surfaceDangerSubtle,
      surfaceWarningSubtle: surfaceWarningSubtle ?? this.surfaceWarningSubtle,
      surfaceSuccessSubtle: surfaceSuccessSubtle ?? this.surfaceSuccessSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverse: textInverse ?? this.textInverse,
      textBrand: textBrand ?? this.textBrand,
      iconPrimary: iconPrimary ?? this.iconPrimary,
      iconSecondary: iconSecondary ?? this.iconSecondary,
      iconInverse: iconInverse ?? this.iconInverse,
      iconBrand: iconBrand ?? this.iconBrand,
      borderPrimary: borderPrimary ?? this.borderPrimary,
      borderSecondary: borderSecondary ?? this.borderSecondary,
      borderFocused: borderFocused ?? this.borderFocused,
      dividerPrimary: dividerPrimary ?? this.dividerPrimary,
      dividerSubtle: dividerSubtle ?? this.dividerSubtle,
      buttonPrimaryBackground:
          buttonPrimaryBackground ?? this.buttonPrimaryBackground,
      buttonPrimaryForeground:
          buttonPrimaryForeground ?? this.buttonPrimaryForeground,
      buttonSecondaryBackground:
          buttonSecondaryBackground ?? this.buttonSecondaryBackground,
      buttonSecondaryForeground:
          buttonSecondaryForeground ?? this.buttonSecondaryForeground,
      buttonTertiaryForeground:
          buttonTertiaryForeground ?? this.buttonTertiaryForeground,
      buttonDangerBackground:
          buttonDangerBackground ?? this.buttonDangerBackground,
      buttonDangerForeground:
          buttonDangerForeground ?? this.buttonDangerForeground,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      inputFocusedBorder: inputFocusedBorder ?? this.inputFocusedBorder,
      inputErrorBorder: inputErrorBorder ?? this.inputErrorBorder,
      selectionBackground: selectionBackground ?? this.selectionBackground,
      selectionForeground: selectionForeground ?? this.selectionForeground,
      toggleActive: toggleActive ?? this.toggleActive,
      toggleInactive: toggleInactive ?? this.toggleInactive,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      pending: pending ?? this.pending,
      approved: approved ?? this.approved,
      rejected: rejected ?? this.rejected,
      archived: archived ?? this.archived,
      scrim: scrim ?? this.scrim,
      dialogBackground: dialogBackground ?? this.dialogBackground,
      bottomSheetBackground:
          bottomSheetBackground ?? this.bottomSheetBackground,
      snackSuccessBackground:
          snackSuccessBackground ?? this.snackSuccessBackground,
      snackErrorBackground: snackErrorBackground ?? this.snackErrorBackground,
      tooltipBackground: tooltipBackground ?? this.tooltipBackground,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }
    return AppThemeColors(
      appBackground: Color.lerp(appBackground, other.appBackground, t)!,
      screenBackground:
          Color.lerp(screenBackground, other.screenBackground, t)!,
      surfacePrimary: Color.lerp(surfacePrimary, other.surfacePrimary, t)!,
      surfaceSecondary:
          Color.lerp(surfaceSecondary, other.surfaceSecondary, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceInteractive:
          Color.lerp(surfaceInteractive, other.surfaceInteractive, t)!,
      surfaceInverse: Color.lerp(surfaceInverse, other.surfaceInverse, t)!,
      surfaceDangerSubtle:
          Color.lerp(surfaceDangerSubtle, other.surfaceDangerSubtle, t)!,
      surfaceWarningSubtle:
          Color.lerp(surfaceWarningSubtle, other.surfaceWarningSubtle, t)!,
      surfaceSuccessSubtle:
          Color.lerp(surfaceSuccessSubtle, other.surfaceSuccessSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      textBrand: Color.lerp(textBrand, other.textBrand, t)!,
      iconPrimary: Color.lerp(iconPrimary, other.iconPrimary, t)!,
      iconSecondary: Color.lerp(iconSecondary, other.iconSecondary, t)!,
      iconInverse: Color.lerp(iconInverse, other.iconInverse, t)!,
      iconBrand: Color.lerp(iconBrand, other.iconBrand, t)!,
      borderPrimary: Color.lerp(borderPrimary, other.borderPrimary, t)!,
      borderSecondary: Color.lerp(borderSecondary, other.borderSecondary, t)!,
      borderFocused: Color.lerp(borderFocused, other.borderFocused, t)!,
      dividerPrimary: Color.lerp(dividerPrimary, other.dividerPrimary, t)!,
      dividerSubtle: Color.lerp(dividerSubtle, other.dividerSubtle, t)!,
      buttonPrimaryBackground: Color.lerp(
          buttonPrimaryBackground, other.buttonPrimaryBackground, t)!,
      buttonPrimaryForeground: Color.lerp(
          buttonPrimaryForeground, other.buttonPrimaryForeground, t)!,
      buttonSecondaryBackground: Color.lerp(
          buttonSecondaryBackground, other.buttonSecondaryBackground, t)!,
      buttonSecondaryForeground: Color.lerp(
          buttonSecondaryForeground, other.buttonSecondaryForeground, t)!,
      buttonTertiaryForeground: Color.lerp(
          buttonTertiaryForeground, other.buttonTertiaryForeground, t)!,
      buttonDangerBackground:
          Color.lerp(buttonDangerBackground, other.buttonDangerBackground, t)!,
      buttonDangerForeground:
          Color.lerp(buttonDangerForeground, other.buttonDangerForeground, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      inputFocusedBorder:
          Color.lerp(inputFocusedBorder, other.inputFocusedBorder, t)!,
      inputErrorBorder:
          Color.lerp(inputErrorBorder, other.inputErrorBorder, t)!,
      selectionBackground:
          Color.lerp(selectionBackground, other.selectionBackground, t)!,
      selectionForeground:
          Color.lerp(selectionForeground, other.selectionForeground, t)!,
      toggleActive: Color.lerp(toggleActive, other.toggleActive, t)!,
      toggleInactive: Color.lerp(toggleInactive, other.toggleInactive, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      approved: Color.lerp(approved, other.approved, t)!,
      rejected: Color.lerp(rejected, other.rejected, t)!,
      archived: Color.lerp(archived, other.archived, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      dialogBackground:
          Color.lerp(dialogBackground, other.dialogBackground, t)!,
      bottomSheetBackground:
          Color.lerp(bottomSheetBackground, other.bottomSheetBackground, t)!,
      snackSuccessBackground:
          Color.lerp(snackSuccessBackground, other.snackSuccessBackground, t)!,
      snackErrorBackground:
          Color.lerp(snackErrorBackground, other.snackErrorBackground, t)!,
      tooltipBackground:
          Color.lerp(tooltipBackground, other.tooltipBackground, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}

@immutable
class AppChartTokens extends ThemeExtension<AppChartTokens> {
  const AppChartTokens({
    required this.chartAxis,
    required this.chartGrid,
    required this.chartTooltipBackground,
    required this.chartTooltipForeground,
    required this.chartSeries,
    required this.chartPositive,
    required this.chartNegative,
    required this.chartNeutral,
  });

  final Color chartAxis;
  final Color chartGrid;
  final Color chartTooltipBackground;
  final Color chartTooltipForeground;
  final List<Color> chartSeries;
  final Color chartPositive;
  final Color chartNegative;
  final Color chartNeutral;

  @override
  AppChartTokens copyWith({
    Color? chartAxis,
    Color? chartGrid,
    Color? chartTooltipBackground,
    Color? chartTooltipForeground,
    List<Color>? chartSeries,
    Color? chartPositive,
    Color? chartNegative,
    Color? chartNeutral,
  }) {
    return AppChartTokens(
      chartAxis: chartAxis ?? this.chartAxis,
      chartGrid: chartGrid ?? this.chartGrid,
      chartTooltipBackground:
          chartTooltipBackground ?? this.chartTooltipBackground,
      chartTooltipForeground:
          chartTooltipForeground ?? this.chartTooltipForeground,
      chartSeries: chartSeries ?? this.chartSeries,
      chartPositive: chartPositive ?? this.chartPositive,
      chartNegative: chartNegative ?? this.chartNegative,
      chartNeutral: chartNeutral ?? this.chartNeutral,
    );
  }

  @override
  AppChartTokens lerp(ThemeExtension<AppChartTokens>? other, double t) {
    if (other is! AppChartTokens) {
      return this;
    }
    return AppChartTokens(
      chartAxis: Color.lerp(chartAxis, other.chartAxis, t)!,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
      chartTooltipBackground:
          Color.lerp(chartTooltipBackground, other.chartTooltipBackground, t)!,
      chartTooltipForeground:
          Color.lerp(chartTooltipForeground, other.chartTooltipForeground, t)!,
      chartSeries: List<Color>.generate(
        chartSeries.length < other.chartSeries.length
            ? chartSeries.length
            : other.chartSeries.length,
        (index) => Color.lerp(chartSeries[index], other.chartSeries[index], t)!,
      ),
      chartPositive: Color.lerp(chartPositive, other.chartPositive, t)!,
      chartNegative: Color.lerp(chartNegative, other.chartNegative, t)!,
      chartNeutral: Color.lerp(chartNeutral, other.chartNeutral, t)!,
    );
  }
}

@immutable
class AppAssetTokens extends ThemeExtension<AppAssetTokens> {
  const AppAssetTokens({
    required this.lightSuffix,
    required this.darkSuffix,
    required this.preferTintableIcons,
  });

  final String lightSuffix;
  final String darkSuffix;
  final bool preferTintableIcons;

  @override
  AppAssetTokens copyWith({
    String? lightSuffix,
    String? darkSuffix,
    bool? preferTintableIcons,
  }) {
    return AppAssetTokens(
      lightSuffix: lightSuffix ?? this.lightSuffix,
      darkSuffix: darkSuffix ?? this.darkSuffix,
      preferTintableIcons: preferTintableIcons ?? this.preferTintableIcons,
    );
  }

  @override
  AppAssetTokens lerp(ThemeExtension<AppAssetTokens>? other, double t) {
    if (other is! AppAssetTokens) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

class ThemeAssetResolver {
  const ThemeAssetResolver._();

  static String resolve({
    required Brightness brightness,
    required String lightAsset,
    String? darkAsset,
  }) {
    if (brightness == Brightness.dark &&
        darkAsset != null &&
        darkAsset.isNotEmpty) {
      return darkAsset;
    }
    return lightAsset;
  }
}
