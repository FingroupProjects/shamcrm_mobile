import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/core/theme/tokens/app_radius_tokens.dart';
import 'package:flutter/material.dart';

class AppCardTheme {
  static CardThemeData build(AppThemeColors colors) {
    return CardThemeData(
      color: colors.surfacePrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadiusTokens.value.card,
      ),
    );
  }
}
