import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/core/theme/tokens/app_radius_tokens.dart';
import 'package:flutter/material.dart';

class AppDialogTheme {
  static DialogThemeData build(
    AppThemeColors colors,
    AppThemeTextStyles textStyles,
  ) {
    return DialogThemeData(
      backgroundColor: colors.surfacePrimary,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textStyles.titleLg,
      contentTextStyle: textStyles.bodyMd.copyWith(color: colors.textSecondary),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadiusTokens.value.card,
      ),
    );
  }
}
