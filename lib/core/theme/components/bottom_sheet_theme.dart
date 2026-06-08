import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/core/theme/tokens/app_radius_tokens.dart';
import 'package:flutter/material.dart';

class AppBottomSheetTheme {
  static BottomSheetThemeData build(AppThemeColors colors) {
    return BottomSheetThemeData(
      backgroundColor: colors.surfacePrimary,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadiusTokens.value.sheet,
      ),
    );
  }
}
