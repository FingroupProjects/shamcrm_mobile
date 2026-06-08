import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/core/theme/typography/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppTextTokens {
  static AppThemeTextStyles fromColors({
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return AppTextStyles.build(textPrimary, textSecondary);
  }

  static TextTheme toTextTheme(AppThemeTextStyles styles) {
    return TextTheme(
      displayLarge: styles.displayLg,
      titleLarge: styles.titleLg,
      titleMedium: styles.titleMd,
      bodyLarge: styles.bodyLg,
      bodyMedium: styles.bodyMd,
      bodySmall: styles.bodySm,
      labelLarge: styles.labelLg,
      labelMedium: styles.labelMd,
      labelSmall: styles.caption,
    );
  }
}
