import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/core/theme/typography/app_font_families.dart';
import 'package:flutter/material.dart';

class AppTextStyles {
  static AppThemeTextStyles build(Color textPrimary, Color textSecondary) {
    return AppThemeTextStyles(
      displayLg: TextStyle(
        fontFamily: AppFontFamilies.gilroy,
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleLg: TextStyle(
        fontFamily: AppFontFamilies.gilroy,
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMd: TextStyle(
        fontFamily: AppFontFamilies.gilroy,
        fontSize: 18,
        height: 1.33,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLg: TextStyle(
        fontFamily: AppFontFamilies.gilroy,
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodyMd: TextStyle(
        fontFamily: AppFontFamilies.gilroy,
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      bodySm: TextStyle(
        fontFamily: AppFontFamilies.gilroy,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelLg: TextStyle(
        fontFamily: AppFontFamilies.gilroy,
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMd: TextStyle(
        fontFamily: AppFontFamilies.gilroy,
        fontSize: 14,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      caption: TextStyle(
        fontFamily: AppFontFamilies.golos,
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
    );
  }
}
