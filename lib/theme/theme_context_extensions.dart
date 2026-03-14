import 'package:crm_task_manager/theme/app_theme_controller.dart';
import 'package:crm_task_manager/theme/app_theme_extensions.dart';
import 'package:crm_task_manager/theme/app_theme_mode.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

extension ThemeContextExtensions on BuildContext {
  AppThemeColors get appColors => Theme.of(this).extension<AppThemeColors>()!;

  AppChartTokens get appCharts => Theme.of(this).extension<AppChartTokens>()!;

  AppAssetTokens get appAssets => Theme.of(this).extension<AppAssetTokens>()!;

  AppThemeController get appThemeController =>
      Provider.of<AppThemeController>(this, listen: false);

  AppThemeMode get appThemeMode => watch<AppThemeController>().mode;

  Brightness get effectiveThemeBrightness =>
      watch<AppThemeController>().effectiveBrightness;
}
