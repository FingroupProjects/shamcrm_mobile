import 'package:crm_task_manager/core/theme/app_theme_data.dart';
import 'package:crm_task_manager/core/theme/palette/dark_palette.dart';
import 'package:crm_task_manager/core/theme/palette/light_palette.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() => AppThemeData.build(
        brightness: Brightness.light,
        palette: LightPalette.value,
      );

  static ThemeData dark() => AppThemeData.build(
        brightness: Brightness.dark,
        palette: DarkPalette.value,
      );
}
