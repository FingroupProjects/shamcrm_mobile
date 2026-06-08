import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class AppTabBarTheme {
  static TabBarThemeData build(
    AppThemeColors colors,
    AppThemeTextStyles textStyles,
  ) {
    return TabBarThemeData(
      labelColor: colors.textPrimary,
      unselectedLabelColor: colors.textSecondary,
      indicatorColor: colors.buttonPrimaryBg,
      labelStyle: textStyles.labelMd,
      unselectedLabelStyle: textStyles.bodyMd,
      dividerColor: colors.borderSubtle,
    );
  }
}
