import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/core/theme/tokens/app_radius_tokens.dart';
import 'package:flutter/material.dart';

class AppButtonTheme {
  static ElevatedButtonThemeData elevated(
    AppThemeColors colors,
    AppThemeTextStyles textStyles,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colors.buttonPrimaryBg,
        foregroundColor: colors.buttonPrimaryFg,
        disabledBackgroundColor: colors.borderSubtle,
        disabledForegroundColor: colors.textMuted,
        textStyle: textStyles.labelLg,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadiusTokens.value.button,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData outlined(
    AppThemeColors colors,
    AppThemeTextStyles textStyles,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.buttonSecondaryFg,
        textStyle: textStyles.labelLg,
        side: BorderSide(color: colors.borderPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadiusTokens.value.button,
        ),
      ),
    );
  }

  static TextButtonThemeData text(
    AppThemeColors colors,
    AppThemeTextStyles textStyles,
  ) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.buttonSecondaryFg,
        textStyle: textStyles.labelMd,
      ),
    );
  }

  static FloatingActionButtonThemeData fab(AppThemeColors colors) {
    return FloatingActionButtonThemeData(
      backgroundColor: colors.buttonPrimaryBg,
      foregroundColor: colors.buttonPrimaryFg,
    );
  }
}
