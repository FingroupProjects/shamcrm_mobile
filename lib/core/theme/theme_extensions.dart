import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.surfacePrimary,
    required this.surfaceElevated,
    required this.surfaceAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.borderPrimary,
    required this.borderSubtle,
    required this.buttonPrimaryBg,
    required this.buttonPrimaryFg,
    required this.buttonSecondaryBg,
    required this.buttonSecondaryFg,
    required this.buttonDangerBg,
    required this.buttonDangerFg,
    required this.fieldBg,
    required this.fieldBorder,
    required this.fieldHint,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.overlay,
    required this.shadow,
  });

  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color surfacePrimary;
  final Color surfaceElevated;
  final Color surfaceAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textInverse;
  final Color iconPrimary;
  final Color iconSecondary;
  final Color borderPrimary;
  final Color borderSubtle;
  final Color buttonPrimaryBg;
  final Color buttonPrimaryFg;
  final Color buttonSecondaryBg;
  final Color buttonSecondaryFg;
  final Color buttonDangerBg;
  final Color buttonDangerFg;
  final Color fieldBg;
  final Color fieldBorder;
  final Color fieldHint;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color overlay;
  final Color shadow;

  // Semantic aliases for UI layer usage.
  Color get background => backgroundPrimary;
  Color get surface => surfacePrimary;
  Color get buttonPrimary => buttonPrimaryBg;
  Color get buttonSecondary => buttonSecondaryBg;
  Color get buttonDanger => buttonDangerBg;
  Color get fieldBackground => fieldBg;
  Color get overlayColor => overlay;
  Color get shadowColor => shadow;

  @override
  AppThemeColors copyWith({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? surfacePrimary,
    Color? surfaceElevated,
    Color? surfaceAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textInverse,
    Color? iconPrimary,
    Color? iconSecondary,
    Color? borderPrimary,
    Color? borderSubtle,
    Color? buttonPrimaryBg,
    Color? buttonPrimaryFg,
    Color? buttonSecondaryBg,
    Color? buttonSecondaryFg,
    Color? buttonDangerBg,
    Color? buttonDangerFg,
    Color? fieldBg,
    Color? fieldBorder,
    Color? fieldHint,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? overlay,
    Color? shadow,
  }) {
    return AppThemeColors(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceAccent: surfaceAccent ?? this.surfaceAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textInverse: textInverse ?? this.textInverse,
      iconPrimary: iconPrimary ?? this.iconPrimary,
      iconSecondary: iconSecondary ?? this.iconSecondary,
      borderPrimary: borderPrimary ?? this.borderPrimary,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      buttonPrimaryBg: buttonPrimaryBg ?? this.buttonPrimaryBg,
      buttonPrimaryFg: buttonPrimaryFg ?? this.buttonPrimaryFg,
      buttonSecondaryBg: buttonSecondaryBg ?? this.buttonSecondaryBg,
      buttonSecondaryFg: buttonSecondaryFg ?? this.buttonSecondaryFg,
      buttonDangerBg: buttonDangerBg ?? this.buttonDangerBg,
      buttonDangerFg: buttonDangerFg ?? this.buttonDangerFg,
      fieldBg: fieldBg ?? this.fieldBg,
      fieldBorder: fieldBorder ?? this.fieldBorder,
      fieldHint: fieldHint ?? this.fieldHint,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      overlay: overlay ?? this.overlay,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }

    return AppThemeColors(
      backgroundPrimary:
          Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      backgroundSecondary:
          Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      surfacePrimary: Color.lerp(surfacePrimary, other.surfacePrimary, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceAccent: Color.lerp(surfaceAccent, other.surfaceAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      iconPrimary: Color.lerp(iconPrimary, other.iconPrimary, t)!,
      iconSecondary: Color.lerp(iconSecondary, other.iconSecondary, t)!,
      borderPrimary: Color.lerp(borderPrimary, other.borderPrimary, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      buttonPrimaryBg: Color.lerp(buttonPrimaryBg, other.buttonPrimaryBg, t)!,
      buttonPrimaryFg: Color.lerp(buttonPrimaryFg, other.buttonPrimaryFg, t)!,
      buttonSecondaryBg:
          Color.lerp(buttonSecondaryBg, other.buttonSecondaryBg, t)!,
      buttonSecondaryFg:
          Color.lerp(buttonSecondaryFg, other.buttonSecondaryFg, t)!,
      buttonDangerBg: Color.lerp(buttonDangerBg, other.buttonDangerBg, t)!,
      buttonDangerFg: Color.lerp(buttonDangerFg, other.buttonDangerFg, t)!,
      fieldBg: Color.lerp(fieldBg, other.fieldBg, t)!,
      fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
      fieldHint: Color.lerp(fieldHint, other.fieldHint, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

@immutable
class AppThemeShadows extends ThemeExtension<AppThemeShadows> {
  const AppThemeShadows({
    required this.card,
    required this.floating,
  });

  final List<BoxShadow> card;
  final List<BoxShadow> floating;

  @override
  AppThemeShadows copyWith({
    List<BoxShadow>? card,
    List<BoxShadow>? floating,
  }) {
    return AppThemeShadows(
      card: card ?? this.card,
      floating: floating ?? this.floating,
    );
  }

  @override
  AppThemeShadows lerp(ThemeExtension<AppThemeShadows>? other, double t) {
    if (other is! AppThemeShadows) {
      return this;
    }

    return AppThemeShadows(
      card: BoxShadow.lerpList(card, other.card, t) ?? card,
      floating: BoxShadow.lerpList(floating, other.floating, t) ?? floating,
    );
  }
}

@immutable
class AppThemeTextStyles extends ThemeExtension<AppThemeTextStyles> {
  const AppThemeTextStyles({
    required this.displayLg,
    required this.titleLg,
    required this.titleMd,
    required this.bodyLg,
    required this.bodyMd,
    required this.bodySm,
    required this.labelLg,
    required this.labelMd,
    required this.caption,
  });

  final TextStyle displayLg;
  final TextStyle titleLg;
  final TextStyle titleMd;
  final TextStyle bodyLg;
  final TextStyle bodyMd;
  final TextStyle bodySm;
  final TextStyle labelLg;
  final TextStyle labelMd;
  final TextStyle caption;

  @override
  AppThemeTextStyles copyWith({
    TextStyle? displayLg,
    TextStyle? titleLg,
    TextStyle? titleMd,
    TextStyle? bodyLg,
    TextStyle? bodyMd,
    TextStyle? bodySm,
    TextStyle? labelLg,
    TextStyle? labelMd,
    TextStyle? caption,
  }) {
    return AppThemeTextStyles(
      displayLg: displayLg ?? this.displayLg,
      titleLg: titleLg ?? this.titleLg,
      titleMd: titleMd ?? this.titleMd,
      bodyLg: bodyLg ?? this.bodyLg,
      bodyMd: bodyMd ?? this.bodyMd,
      bodySm: bodySm ?? this.bodySm,
      labelLg: labelLg ?? this.labelLg,
      labelMd: labelMd ?? this.labelMd,
      caption: caption ?? this.caption,
    );
  }

  @override
  AppThemeTextStyles lerp(ThemeExtension<AppThemeTextStyles>? other, double t) {
    if (other is! AppThemeTextStyles) {
      return this;
    }

    return AppThemeTextStyles(
      displayLg: TextStyle.lerp(displayLg, other.displayLg, t)!,
      titleLg: TextStyle.lerp(titleLg, other.titleLg, t)!,
      titleMd: TextStyle.lerp(titleMd, other.titleMd, t)!,
      bodyLg: TextStyle.lerp(bodyLg, other.bodyLg, t)!,
      bodyMd: TextStyle.lerp(bodyMd, other.bodyMd, t)!,
      bodySm: TextStyle.lerp(bodySm, other.bodySm, t)!,
      labelLg: TextStyle.lerp(labelLg, other.labelLg, t)!,
      labelMd: TextStyle.lerp(labelMd, other.labelMd, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
    );
  }
}
