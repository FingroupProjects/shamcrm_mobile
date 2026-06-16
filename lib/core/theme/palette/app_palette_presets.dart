import 'dart:math' as math;

import 'package:crm_task_manager/core/theme/palette/app_palette.dart';
import 'package:crm_task_manager/core/theme/palette/dark_palette.dart';
import 'package:flutter/material.dart';

enum AppPalettePreset {
  custom,
  monochrome,
  analogous,
  complementary,
  triadic,
  tetradic,
  sunset,
}

extension AppPalettePresetX on AppPalettePreset {
  String get storageKey => switch (this) {
        AppPalettePreset.custom => 'custom',
        AppPalettePreset.monochrome => 'monochrome',
        AppPalettePreset.analogous => 'analogous',
        AppPalettePreset.complementary => 'complementary',
        AppPalettePreset.triadic => 'triadic',
        AppPalettePreset.tetradic => 'tetradic',
        AppPalettePreset.sunset => 'sunset',
      };

  String get title => switch (this) {
        AppPalettePreset.custom => 'Палитра',
        AppPalettePreset.monochrome => 'Монохром',
        AppPalettePreset.analogous => 'Аналоговая',
        AppPalettePreset.complementary => 'Комплементарная',
        AppPalettePreset.triadic => 'Триада',
        AppPalettePreset.tetradic => 'Тетрада',
        AppPalettePreset.sunset => 'Закат',
      };

  String get subtitle => switch (this) {
        AppPalettePreset.custom => 'Любой цвет из палитры',
        AppPalettePreset.monochrome => 'Спокойная схема в одном цвете',
        AppPalettePreset.analogous => 'Мягкий переход соседних оттенков',
        AppPalettePreset.complementary => 'Контрастная пара на круге',
        AppPalettePreset.triadic => 'Три равномерных цвета',
        AppPalettePreset.tetradic => 'Четыре выразительных акцента',
        AppPalettePreset.sunset => 'Теплая авторская схема',
      };

  AppPalette lightPaletteForSeed([Color? customSeed]) {
    if (this == AppPalettePreset.custom) {
      return _buildPalette(
        seed: customSeed ?? const Color(0xFF0EA5E9),
        accentHueShift: 0.08,
        infoHueShift: 0.55,
      );
    }
    return lightPalette;
  }

  AppPalette darkPaletteForSeed([Color? customSeed]) {
    final palette = lightPaletteForSeed(customSeed);
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

  AppPalette get lightPalette {
    return switch (this) {
      AppPalettePreset.custom => _buildPalette(
          seed: const Color(0xFF0EA5E9),
          accentHueShift: 0.08,
          infoHueShift: 0.55,
        ),
      AppPalettePreset.monochrome => _buildPalette(
          seed: const Color(0xFF334155),
          accentHueShift: 0.02,
          infoHueShift: 0.04,
        ),
      AppPalettePreset.analogous => _buildPalette(
          seed: const Color(0xFF0EA5E9),
          accentHueShift: 0.08,
          infoHueShift: 0.12,
        ),
      AppPalettePreset.complementary => _buildPalette(
          seed: const Color(0xFF7C3AED),
          accentHueShift: 0.5,
          infoHueShift: 0.52,
        ),
      AppPalettePreset.triadic => _buildPalette(
          seed: const Color(0xFF16A34A),
          accentHueShift: 0.33,
          infoHueShift: 0.66,
        ),
      AppPalettePreset.tetradic => _buildPalette(
          seed: const Color(0xFFEA580C),
          accentHueShift: 0.25,
          infoHueShift: 0.5,
        ),
      AppPalettePreset.sunset => _sunsetLightPalette,
    };
  }

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
      orElse: () => AppPalettePreset.custom,
    );
  }
}

AppPalette _buildPalette({
  required Color seed,
  required double accentHueShift,
  required double infoHueShift,
}) {
  final hsl = HSLColor.fromColor(seed);
  final isNearWhite = hsl.lightness >= 0.92;
  final isLowChroma = hsl.saturation <= 0.08;
  final useNeutralizedLightSeed = isNearWhite && isLowChroma;

  Color shifted(double amount, {double saturationBoost = 0.0}) {
    final hue = (hsl.hue + amount * 360) % 360;
    final saturation = useNeutralizedLightSeed
        ? (hsl.saturation + saturationBoost).clamp(0.0, 0.14)
        : (hsl.saturation + saturationBoost).clamp(0.45, 0.95);
    final lightness = useNeutralizedLightSeed
        ? hsl.lightness.clamp(0.84, 0.94)
        : hsl.lightness.clamp(0.26, 0.72);
    return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
  }

  final primary500 = shifted(0, saturationBoost: 0.12);
  final accent500 = shifted(accentHueShift, saturationBoost: 0.08);
  final info500 = shifted(infoHueShift, saturationBoost: 0.02);
  final success500 = shifted(0.28, saturationBoost: -0.02);
  final warning500 = shifted(0.12, saturationBoost: 0.06);
  final danger500 = shifted(0.56, saturationBoost: 0.08);

  final neutralSeed =
      useNeutralizedLightSeed ? const Color(0xFFEFF3F8) : primary500;

  return AppPalette(
    primary500: primary500,
    primary700: _darken(primary500, 0.22),
    accent500: accent500,
    neutral0: const Color(0xFFFFFCFA),
    neutral50: _tint(neutralSeed, 0.96),
    neutral100: _tint(neutralSeed, 0.9),
    neutral200: _tint(neutralSeed, 0.82),
    neutral300: _tint(neutralSeed, 0.7),
    neutral400: _tint(neutralSeed, 0.55),
    neutral500: _tint(neutralSeed, 0.42),
    neutral600: _shade(neutralSeed, 0.24),
    neutral700: _shade(neutralSeed, 0.36),
    neutral800: _shade(neutralSeed, 0.48),
    neutral900: _shade(neutralSeed, 0.62),
    success500: success500,
    warning500: warning500,
    danger500: danger500,
    info500: info500,
  );
}

Color _darken(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

Color _shade(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

Color _tint(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final mix = amount.clamp(0.0, 1.0);
  return HSLColor.fromAHSL(
    1,
    hsl.hue,
    math.min(hsl.saturation + 0.04, 1.0),
    mix,
  ).toColor();
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
