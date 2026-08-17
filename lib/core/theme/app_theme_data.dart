import 'package:crm_task_manager/core/navigation/app_swipe_back.dart';
import 'package:crm_task_manager/core/theme/components/app_bar_theme.dart';
import 'package:crm_task_manager/core/theme/components/bottom_sheet_theme.dart';
import 'package:crm_task_manager/core/theme/components/button_theme.dart';
import 'package:crm_task_manager/core/theme/components/card_theme.dart';
import 'package:crm_task_manager/core/theme/components/dialog_theme.dart';
import 'package:crm_task_manager/core/theme/components/input_theme.dart';
import 'package:crm_task_manager/core/theme/components/tab_bar_theme.dart';
import 'package:crm_task_manager/core/theme/palette/app_palette.dart';
import 'package:crm_task_manager/core/theme/tokens/app_shadow_tokens.dart';
import 'package:crm_task_manager/core/theme/tokens/app_color_tokens.dart';
import 'package:crm_task_manager/core/theme/tokens/app_text_tokens.dart';
import 'package:crm_task_manager/core/theme/typography/app_font_families.dart';
import 'package:flutter/material.dart';

class AppThemeData {
  static ThemeData build({
    required Brightness brightness,
    required AppPalette palette,
  }) {
    final colors = AppColorTokens.fromPalette(palette, brightness: brightness);
    final textStyles = AppTextTokens.fromColors(
      textPrimary: colors.textPrimary,
      textSecondary: colors.textSecondary,
    );
    final shadows = AppShadowTokens.build(colors.shadow);
    final textTheme = AppTextTokens.toTextTheme(textStyles);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.brandPrimary,
      brightness: brightness,
    ).copyWith(
      primary: colors.buttonPrimaryBg,
      onPrimary: colors.buttonPrimaryFg,
      secondary: palette.brandPrimary,
      onSecondary: colors.textInverse,
      tertiary: colors.info,
      onTertiary: colors.textInverse,
      error: colors.error,
      onError: colors.textInverse,
      surface: colors.surfacePrimary,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.borderPrimary,
      outlineVariant: colors.borderSubtle,
      shadow: colors.shadow,
      scrim: colors.overlay,
      inverseSurface: colors.textPrimary,
      onInverseSurface: colors.surfacePrimary,
      inversePrimary: palette.brandAccent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppFontFamilies.gilroy,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.backgroundPrimary,
      canvasColor: colors.backgroundPrimary,
      dividerColor: colors.borderSubtle,
      shadowColor: colors.shadow,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: AppCupertinoPageTransitionsBuilder(),
          TargetPlatform.android: AppCupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: AppCupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: AppCupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: AppCupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppCupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: textTheme,
      appBarTheme: AppAppBarTheme.build(colors, textStyles),
      iconTheme: IconThemeData(color: colors.iconPrimary),
      cardColor: colors.surfacePrimary,
      cardTheme: AppCardTheme.build(colors),
      dialogTheme: AppDialogTheme.build(colors, textStyles),
      bottomSheetTheme: AppBottomSheetTheme.build(colors),
      inputDecorationTheme: AppInputTheme.build(colors, textStyles),
      elevatedButtonTheme: AppButtonTheme.elevated(colors, textStyles),
      outlinedButtonTheme: AppButtonTheme.outlined(colors, textStyles),
      textButtonTheme: AppButtonTheme.text(colors, textStyles),
      floatingActionButtonTheme: AppButtonTheme.fab(colors),
      tabBarTheme: AppTabBarTheme.build(colors, textStyles),
      extensions: <ThemeExtension<dynamic>>[
        colors,
        textStyles,
        shadows,
      ],
    );
  }
}
