import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/core/theme/tokens/app_radius_tokens.dart';
import 'package:flutter/material.dart';

class AppInputTheme {
  static InputDecorationTheme build(
    AppThemeColors colors,
    AppThemeTextStyles textStyles,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colors.fieldBg,
      hintStyle: textStyles.bodyMd.copyWith(color: colors.fieldHint),
      labelStyle: textStyles.bodyMd.copyWith(color: colors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: AppRadiusTokens.value.input,
        borderSide: BorderSide(color: colors.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadiusTokens.value.input,
        borderSide: BorderSide(color: colors.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadiusTokens.value.input,
        borderSide: BorderSide(color: colors.buttonPrimaryBg, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadiusTokens.value.input,
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadiusTokens.value.input,
        borderSide: BorderSide(color: colors.error, width: 1.4),
      ),
    );
  }
}
