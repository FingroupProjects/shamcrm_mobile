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
}
