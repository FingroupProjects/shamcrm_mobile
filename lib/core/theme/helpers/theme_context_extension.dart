import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/core/theme/tokens/app_radius_tokens.dart';
import 'package:crm_task_manager/core/theme/tokens/app_spacing_tokens.dart';
import 'package:flutter/material.dart';

extension ThemeContextExtension on BuildContext {
  AppThemeColors get appColors => Theme.of(this).extension<AppThemeColors>()!;
  AppThemeTextStyles get appTextStyles =>
      Theme.of(this).extension<AppThemeTextStyles>()!;
  AppThemeShadows get appShadows =>
      Theme.of(this).extension<AppThemeShadows>()!;
  AppSpacingTokens get appSpacing => AppSpacingTokens.value;
  AppRadiusTokens get appRadius => AppRadiusTokens.value;

  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  /// Dark toast chip. Never white — dark palettes map textPrimary to off-white.
  Color get toastBackground {
    if (isDarkTheme) {
      return appColors.surfaceElevated;
    }
    final brand = appColors.textPrimary;
    return brand.computeLuminance() < 0.45 ? brand : appColors.backgroundPrimary;
  }

  Color get toastForeground {
    return useLightForeground(toastBackground)
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);
  }

  Color get toastAction {
    final background = toastBackground;
    final primary = appColors.buttonPrimaryBg;
    final primaryContrast =
        (primary.computeLuminance() - background.computeLuminance()).abs();
    if (primaryContrast >= 0.28 &&
        (primary.computeLuminance() >= 0.35 ||
            background.computeLuminance() >= 0.35)) {
      return primary;
    }
    return appColors.info;
  }

  bool useLightForeground(Color background, {double threshold = 0.45}) {
    return background.computeLuminance() < threshold;
  }

  Color adaptiveForegroundOn(
    Color background, {
    Color? lightColor,
    Color? darkColor,
  }) {
    return useLightForeground(background)
        ? (lightColor ??
            (appColors.textInverse.computeLuminance() > 0.5
                ? appColors.textInverse
                : const Color(0xFFF8FAFC)))
        : (darkColor ??
            (appColors.textPrimary.computeLuminance() < 0.5
                ? appColors.textPrimary
                : const Color(0xFF0F172A)));
  }

  Color adaptiveHintOn(
    Color background, {
    double lightAlpha = 0.58,
  }) {
    return useLightForeground(background)
        ? appColors.textInverse.withValues(alpha: lightAlpha)
        : appColors.fieldHint;
  }

  Color adaptiveBorderOn(
    Color background, {
    double lightAlpha = 0.14,
    double darkAlpha = 0.7,
  }) {
    return useLightForeground(background)
        ? appColors.textInverse.withValues(alpha: lightAlpha)
        : appColors.borderSubtle.withValues(alpha: darkAlpha);
  }

  Color adaptiveFocusBorderOn(Color background) {
    return useLightForeground(background)
        ? appColors.textInverse.withValues(alpha: 0.4)
        : appColors.borderPrimary;
  }
}
