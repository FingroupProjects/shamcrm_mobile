import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

@immutable
class AppShadowTokens {
  const AppShadowTokens._();

  static List<BoxShadow> card(Color shadowColor) => [
        BoxShadow(
          color: shadowColor,
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> floating(Color shadowColor) => [
        BoxShadow(
          color: shadowColor,
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static AppThemeShadows build(Color shadowColor) {
    return AppThemeShadows(
      card: card(shadowColor),
      floating: floating(shadowColor),
    );
  }
}
