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

  bool useLightForeground(Color background, {double threshold = 0.45}) {
    return background.computeLuminance() < threshold;
  }

  Color adaptiveForegroundOn(
    Color background, {
    Color? lightColor,
    Color? darkColor,
  }) {
    return useLightForeground(background)
        ? (lightColor ?? appColors.textInverse)
        : (darkColor ?? appColors.textPrimary);
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
