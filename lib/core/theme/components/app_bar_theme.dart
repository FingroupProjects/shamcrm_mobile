import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class AppAppBarTheme {
  static AppBarTheme build(
    AppThemeColors colors,
    AppThemeTextStyles textStyles,
  ) {
    return AppBarTheme(
      backgroundColor: colors.surfacePrimary,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: colors.iconPrimary),
      titleTextStyle: textStyles.titleLg,
    );
  }
}
