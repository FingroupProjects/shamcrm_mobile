import 'package:crm_task_manager/core/theme/palette/app_palette.dart';
import 'package:crm_task_manager/core/theme/palette/blue_palette.dart';
import 'package:crm_task_manager/core/theme/palette/dark_palette.dart';
import 'package:crm_task_manager/core/theme/palette/green_palette.dart';
import 'package:crm_task_manager/core/theme/palette/light_palette.dart';
import 'package:flutter/material.dart';

enum AppPalettePreset {
  sham,
  ocean,
  forest,
  sunset,
}

extension AppPalettePresetX on AppPalettePreset {
  String get storageKey => switch (this) {
        AppPalettePreset.sham => 'sham',
        AppPalettePreset.ocean => 'ocean',
        AppPalettePreset.forest => 'forest',
        AppPalettePreset.sunset => 'sunset',
      };

  String get title => switch (this) {
        AppPalettePreset.sham => 'ShamCRM',
        AppPalettePreset.ocean => 'Ocean',
        AppPalettePreset.forest => 'Forest',
        AppPalettePreset.sunset => 'Sunset',
      };

  AppPalette get lightPalette => switch (this) {
        AppPalettePreset.sham => LightPalette.value,
        AppPalettePreset.ocean => BluePalette.value,
        AppPalettePreset.forest => GreenPalette.value,
        AppPalettePreset.sunset => _sunsetLightPalette,
      };

  AppPalette get darkPalette {
    final palette = lightPalette;
    return AppPalette(
      primary500: palette.primary500,
      primary700: DarkPalette.primary700,
      accent500: palette.accent500,
      neutral0: DarkPalette.neutral0,
      neutral50: DarkPalette.neutral50,
      neutral100: DarkPalette.neutral100,
      neutral200: DarkPalette.neutral200,
      neutral300: DarkPalette.neutral300,
      neutral400: DarkPalette.neutral400,
      neutral500: DarkPalette.neutral500,
      neutral600: DarkPalette.neutral600,
      neutral700: DarkPalette.neutral700,
      neutral800: DarkPalette.neutral800,
      neutral900: DarkPalette.neutral900,
      success500: palette.success500,
      warning500: palette.warning500,
      danger500: palette.danger500,
      info500: palette.info500,
    );
  }

  static AppPalettePreset fromStorageKey(String? value) {
    return AppPalettePreset.values.firstWhere(
      (preset) => preset.storageKey == value,
      orElse: () => AppPalettePreset.sham,
    );
  }
}

const AppPalette _sunsetLightPalette = AppPalette(
  primary500: Color(0xFFB45309),
  primary700: Color(0xFF4A2404),
  accent500: Color(0xFFE11D48),
  neutral0: Color(0xFFFFFCFA),
  neutral50: Color(0xFFFFF7F2),
  neutral100: Color(0xFFFDEFE5),
  neutral200: Color(0xFFF7DFCF),
  neutral300: Color(0xFFEBC2AB),
  neutral400: Color(0xFFD3A185),
  neutral500: Color(0xFFB6846A),
  neutral600: Color(0xFF8F6652),
  neutral700: Color(0xFF67493E),
  neutral800: Color(0xFF47302E),
  neutral900: Color(0xFF281A1B),
  success500: Color(0xFF2F9E44),
  warning500: Color(0xFFF59E0B),
  danger500: Color(0xFFE11D48),
  info500: Color(0xFFEA580C),
);
