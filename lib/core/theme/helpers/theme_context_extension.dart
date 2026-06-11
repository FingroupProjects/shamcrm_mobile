import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:flutter/material.dart';

class AppThemeColorsCompat {
  const AppThemeColorsCompat._(this.isDarkMode);

  final bool isDarkMode;

  Color get backgroundPrimary =>
      isDarkMode ? const Color(0xFF0A0E27) : AppColors.backgroundPrimaryWhite100;
  Color get backgroundSecondary =>
      isDarkMode ? const Color(0xFF1E293B) : AppColors.backgroundGray35;
  Color get surfacePrimary =>
      isDarkMode ? const Color(0xFF1E293B) : AppColors.backgroundPrimaryWhite100;
  Color get surfaceElevated =>
      isDarkMode ? const Color(0xFF334155) : AppColors.backgroundGray50;
  Color get surfaceAccent =>
      isDarkMode ? const Color(0xFF23304A) : AppColors.backgroundPrimaryBlue35;

  Color get textPrimary =>
      isDarkMode ? AppColors.textPrimaryWhite : AppColors.primaryBlue;
  Color get textSecondary =>
      isDarkMode ? const Color(0xFF94A3B8) : AppColors.textPrimary800;
  Color get textMuted =>
      isDarkMode ? const Color(0xFF64748B) : AppColors.textPrimary700;
  Color get textInverse => AppColors.textPrimaryWhite;

  Color get iconPrimary => textPrimary;
  Color get iconSecondary => textSecondary;

  Color get borderPrimary =>
      isDarkMode ? const Color(0xFF334155) : AppColors.appCustomDividerColor;
  Color get borderSubtle =>
      isDarkMode ? const Color(0xFF263244) : AppColors.strokePrimaryBlack500;

  Color get buttonPrimaryBg => AppColors.primaryBlue;
  Color get buttonPrimaryFg => AppColors.textPrimaryWhite;
  Color get buttonSecondaryBg =>
      isDarkMode ? const Color(0xFF1E293B) : AppColors.buttonSecondary;
  Color get buttonSecondaryFg =>
      isDarkMode ? AppColors.textPrimaryWhite : AppColors.primaryBlue;
  Color get buttonDangerBg => AppColors.errorColor;
  Color get buttonDangerFg => AppColors.textPrimaryWhite;

  Color get fieldBg =>
      isDarkMode ? const Color(0xFF162033) : AppColors.backgroundPrimaryWhite100;
  Color get fieldBorder =>
      isDarkMode ? const Color(0xFF334155) : AppColors.strokePrimaryBlack500;
  Color get fieldHint =>
      isDarkMode ? const Color(0xFF94A3B8) : AppColors.textPrimary700;

  Color get success => AppColors.textAdditionalGreen;
  Color get warning => AppColors.textAdditionalOrange;
  Color get error => AppColors.errorColor;
  Color get info => AppColors.textAdditionalBlue;
  Color get overlay => Colors.black.withValues(alpha: isDarkMode ? 0.42 : 0.18);
  Color get shadow =>
      Colors.black.withValues(alpha: isDarkMode ? 0.24 : 0.06);
}

class AppThemeTextStylesCompat {
  const AppThemeTextStylesCompat._(this.colors);

  final AppThemeColorsCompat colors;

  TextStyle get titleLg => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: 'Gilroy',
        color: colors.textPrimary,
      );

  TextStyle get titleMd => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Gilroy',
        color: colors.textPrimary,
      );

  TextStyle get bodyLg => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gilroy',
        color: colors.textPrimary,
      );

  TextStyle get bodyMd => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gilroy',
        color: colors.textPrimary,
      );

  TextStyle get bodySm => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gilroy',
        color: colors.textSecondary,
      );

  TextStyle get caption => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gilroy',
        color: colors.textSecondary,
      );
}

class AppThemeShadowsCompat {
  const AppThemeShadowsCompat._(this.colors);

  final AppThemeColorsCompat colors;

  List<BoxShadow> get card => [
        BoxShadow(
          color: colors.shadow,
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

extension ThemeContextExtension on BuildContext {
  bool get _isDarkMode => Theme.of(this).brightness == Brightness.dark;

  AppThemeColorsCompat get appColors => AppThemeColorsCompat._(_isDarkMode);
  AppThemeTextStylesCompat get appTextStyles =>
      AppThemeTextStylesCompat._(appColors);
  AppThemeShadowsCompat get appShadows => AppThemeShadowsCompat._(appColors);
}
