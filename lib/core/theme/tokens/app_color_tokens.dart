import 'package:crm_task_manager/core/theme/palette/app_palette.dart';
import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class AppColorTokens {
  static AppThemeColors fromPalette(
    AppPalette palette, {
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    return AppThemeColors(
      backgroundPrimary: isDark ? palette.neutral50 : palette.neutral0,
      backgroundSecondary: isDark ? palette.neutral100 : palette.neutral100,
      surfacePrimary: isDark ? palette.neutral200 : palette.neutral0,
      surfaceElevated: isDark ? palette.neutral300 : palette.neutral50,
      surfaceAccent: isDark
          ? palette.primary500.withValues(alpha: 0.14)
          : const Color(0xFFF0F6FA),
      textPrimary: isDark ? palette.neutral900 : palette.primary700,
      textSecondary: isDark ? palette.neutral700 : palette.neutral800,
      textMuted: isDark ? palette.neutral600 : palette.neutral600,
      textInverse: isDark ? palette.neutral0 : palette.neutral0,
      iconPrimary: isDark ? palette.neutral900 : palette.primary700,
      iconSecondary: isDark ? palette.neutral700 : palette.neutral700,
      borderPrimary: isDark ? palette.neutral400 : palette.neutral300,
      borderSubtle: isDark ? palette.neutral300 : palette.neutral200,
      buttonPrimaryBg: isDark ? palette.primary500 : palette.primary700,
      buttonPrimaryFg: palette.neutral0,
      buttonSecondaryBg: isDark ? palette.neutral300 : palette.neutral0,
      buttonSecondaryFg: isDark ? palette.neutral900 : palette.primary700,
      buttonDangerBg: palette.danger500,
      buttonDangerFg: palette.neutral0,
      fieldBg: isDark ? palette.neutral200 : palette.neutral0,
      fieldBorder: isDark ? palette.neutral400 : palette.neutral300,
      fieldHint: isDark ? palette.neutral600 : palette.neutral600,
      success: palette.success500,
      warning: palette.warning500,
      error: palette.danger500,
      info: palette.info500,
      overlay: isDark
          ? Colors.black.withValues(alpha: 0.45)
          : Colors.black.withValues(alpha: 0.18),
      shadow: isDark
          ? Colors.black.withValues(alpha: 0.24)
          : Colors.black.withValues(alpha: 0.06),
    );
  }
}
