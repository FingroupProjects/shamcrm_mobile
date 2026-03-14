import 'package:crm_task_manager/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

class AppThemeData {
  const AppThemeData._();

  static ThemeData light() {
    const colors = AppThemeColors(
      appBackground: Color(0xFFF3F6FC),
      screenBackground: Color(0xFFF8FAFD),
      surfacePrimary: Color(0xFFFFFFFF),
      surfaceSecondary: Color(0xFFF4F7FD),
      surfaceElevated: Color(0xFFFFFFFF),
      surfaceInteractive: Color(0xFFEFF4FF),
      surfaceInverse: Color(0xFF1E2E52),
      surfaceDangerSubtle: Color(0xFFFFEEF2),
      surfaceWarningSubtle: Color(0xFFFFF6E5),
      surfaceSuccessSubtle: Color(0xFFEAF7F0),
      textPrimary: Color(0xFF1E2E52),
      textSecondary: Color(0xFF61708C),
      textTertiary: Color(0xFF99A4BA),
      textInverse: Color(0xFFF7F9FF),
      textBrand: Color(0xFF4759FF),
      iconPrimary: Color(0xFF1E2E52),
      iconSecondary: Color(0xFF7D8BA3),
      iconInverse: Color(0xFFF7F9FF),
      iconBrand: Color(0xFF4759FF),
      borderPrimary: Color(0xFFD7DFEE),
      borderSecondary: Color(0xFFE8EEF7),
      borderFocused: Color(0xFF4759FF),
      dividerPrimary: Color(0xFFE2E8F3),
      dividerSubtle: Color(0xFFF0F3F8),
      buttonPrimaryBackground: Color(0xFF1E2E52),
      buttonPrimaryForeground: Color(0xFFFFFFFF),
      buttonSecondaryBackground: Color(0xFFEFF4FF),
      buttonSecondaryForeground: Color(0xFF1E2E52),
      buttonTertiaryForeground: Color(0xFF4759FF),
      buttonDangerBackground: Color(0xFFD9415D),
      buttonDangerForeground: Color(0xFFFFFFFF),
      inputBackground: Color(0xFFF4F7FD),
      inputBorder: Color(0xFFD7DFEE),
      inputFocusedBorder: Color(0xFF4759FF),
      inputErrorBorder: Color(0xFFD9415D),
      selectionBackground: Color(0xFF4759FF),
      selectionForeground: Color(0xFFFFFFFF),
      toggleActive: Color(0xFF4759FF),
      toggleInactive: Color(0xFFC4CDDC),
      success: Color(0xFF27AE60),
      warning: Color(0xFFFF9000),
      error: Color(0xFFF2376F),
      info: Color(0xFF00B8D7),
      pending: Color(0xFFFFB547),
      approved: Color(0xFF27AE60),
      rejected: Color(0xFFD9415D),
      archived: Color(0xFF8A95A8),
      scrim: Color(0x800B1220),
      dialogBackground: Color(0xFFFFFFFF),
      bottomSheetBackground: Color(0xFFFDFEFF),
      snackSuccessBackground: Color(0xFF1F8F4E),
      snackErrorBackground: Color(0xFFB92F49),
      tooltipBackground: Color(0xFF1E2E52),
      shadowColor: Color(0x140C1528),
    );

    const charts = AppChartTokens(
      chartAxis: Color(0xFF71809A),
      chartGrid: Color(0xFFE2E8F3),
      chartTooltipBackground: Color(0xFF1E2E52),
      chartTooltipForeground: Color(0xFFF7F9FF),
      chartSeries: <Color>[
        Color(0xFF4759FF),
        Color(0xFF00B8D7),
        Color(0xFF6A67F8),
        Color(0xFFFF9000),
        Color(0xFF27AE60),
      ],
      chartPositive: Color(0xFF27AE60),
      chartNegative: Color(0xFFF2376F),
      chartNeutral: Color(0xFF99A4BA),
    );

    const assets = AppAssetTokens(
      lightSuffix: '_light',
      darkSuffix: '_dark',
      preferTintableIcons: true,
    );

    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF4759FF),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF00B8D7),
      onSecondary: Color(0xFFFFFFFF),
      error: Color(0xFFF2376F),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1E2E52),
      tertiary: Color(0xFF6A67F8),
      onTertiary: Color(0xFFFFFFFF),
    );

    final textTheme = _buildTextTheme(
      baseColor: colors.textPrimary,
      secondaryColor: colors.textSecondary,
      tertiaryColor: colors.textTertiary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.screenBackground,
      canvasColor: colors.surfacePrimary,
      shadowColor: colors.shadowColor,
      splashColor: colors.selectionBackground.withValues(alpha: 0.08),
      highlightColor: colors.selectionBackground.withValues(alpha: 0.05),
      dividerColor: colors.dividerPrimary,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.selectionBackground,
        selectionColor: colors.selectionBackground.withValues(alpha: 0.18),
        selectionHandleColor: colors.selectionBackground,
      ),
      dividerTheme: DividerThemeData(
        color: colors.dividerPrimary,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.snackSuccessBackground,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textInverse,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.dialogBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.bottomSheetBackground,
        modalBackgroundColor: colors.bottomSheetBackground,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderPrimary),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colors.surfaceSecondary,
        linearTrackColor: colors.surfaceSecondary,
      ),
      inputDecorationTheme: _buildInputDecorationTheme(colors, textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surfacePrimary,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: colors.iconPrimary),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.textBrand,
        unselectedLabelColor: colors.textSecondary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colors.textBrand, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.toggleActive;
          }
          return colors.toggleInactive;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: colors.borderPrimary),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.selectionBackground;
          }
          return colors.surfacePrimary;
        }),
        checkColor: WidgetStateProperty.all(colors.selectionForeground),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.selectionBackground;
          }
          return colors.borderPrimary;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceSecondary,
        selectedColor: colors.surfaceInteractive,
        disabledColor: colors.surfaceSecondary.withValues(alpha: 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.borderPrimary),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
        secondaryLabelStyle:
            textTheme.bodyMedium?.copyWith(color: colors.textBrand),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.surfaceInteractive,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? colors.textBrand : colors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.iconBrand : colors.iconSecondary,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surfacePrimary,
        selectedItemColor: colors.iconBrand,
        unselectedItemColor: colors.iconSecondary,
        selectedLabelStyle:
            textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.dialogBackground,
        surfaceTintColor: Colors.transparent,
        headerForegroundColor: colors.textInverse,
        headerBackgroundColor: colorScheme.primary,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.textInverse;
          }
          return colors.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(colorScheme.primary),
        todayBorder: BorderSide(color: colorScheme.primary),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colors.dialogBackground,
        hourMinuteTextColor: colors.textPrimary,
        dayPeriodTextColor: colors.textPrimary,
        dialHandColor: colorScheme.primary,
        dialTextColor: colors.textPrimary,
        entryModeIconColor: colors.iconPrimary,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        colors,
        charts,
        assets,
      ],
    );
  }

  static ThemeData dark() {
    const colors = AppThemeColors(
      appBackground: Color(0xFF09111F),
      screenBackground: Color(0xFF0D1728),
      surfacePrimary: Color(0xFF132033),
      surfaceSecondary: Color(0xFF1A2942),
      surfaceElevated: Color(0xFF1D2D48),
      surfaceInteractive: Color(0xFF223859),
      surfaceInverse: Color(0xFFF4F7FC),
      surfaceDangerSubtle: Color(0xFF3B1C27),
      surfaceWarningSubtle: Color(0xFF3A2812),
      surfaceSuccessSubtle: Color(0xFF183226),
      textPrimary: Color(0xFFEAF1FF),
      textSecondary: Color(0xFFAAB8CF),
      textTertiary: Color(0xFF7F8CA3),
      textInverse: Color(0xFF0D1728),
      textBrand: Color(0xFF90A0FF),
      iconPrimary: Color(0xFFEAF1FF),
      iconSecondary: Color(0xFFAAB8CF),
      iconInverse: Color(0xFF0D1728),
      iconBrand: Color(0xFF90A0FF),
      borderPrimary: Color(0xFF2B3C57),
      borderSecondary: Color(0xFF24334D),
      borderFocused: Color(0xFF90A0FF),
      dividerPrimary: Color(0xFF24334D),
      dividerSubtle: Color(0xFF1A2840),
      buttonPrimaryBackground: Color(0xFF90A0FF),
      buttonPrimaryForeground: Color(0xFF0D1728),
      buttonSecondaryBackground: Color(0xFF223859),
      buttonSecondaryForeground: Color(0xFFEAF1FF),
      buttonTertiaryForeground: Color(0xFF90A0FF),
      buttonDangerBackground: Color(0xFFF06A84),
      buttonDangerForeground: Color(0xFF0D1728),
      inputBackground: Color(0xFF1A2942),
      inputBorder: Color(0xFF2B3C57),
      inputFocusedBorder: Color(0xFF90A0FF),
      inputErrorBorder: Color(0xFFF06A84),
      selectionBackground: Color(0xFF90A0FF),
      selectionForeground: Color(0xFF0D1728),
      toggleActive: Color(0xFF90A0FF),
      toggleInactive: Color(0xFF42536E),
      success: Color(0xFF5ED39A),
      warning: Color(0xFFFFB961),
      error: Color(0xFFFF7C96),
      info: Color(0xFF60D9F5),
      pending: Color(0xFFFFC978),
      approved: Color(0xFF5ED39A),
      rejected: Color(0xFFFF7C96),
      archived: Color(0xFF90A0B8),
      scrim: Color(0xB309111F),
      dialogBackground: Color(0xFF16243A),
      bottomSheetBackground: Color(0xFF152338),
      snackSuccessBackground: Color(0xFF1C7D53),
      snackErrorBackground: Color(0xFFA63E53),
      tooltipBackground: Color(0xFFEAF1FF),
      shadowColor: Color(0x66000000),
    );

    const charts = AppChartTokens(
      chartAxis: Color(0xFF91A0B8),
      chartGrid: Color(0xFF24334D),
      chartTooltipBackground: Color(0xFFEAF1FF),
      chartTooltipForeground: Color(0xFF0D1728),
      chartSeries: <Color>[
        Color(0xFF90A0FF),
        Color(0xFF60D9F5),
        Color(0xFFACA6FF),
        Color(0xFFFFB961),
        Color(0xFF5ED39A),
      ],
      chartPositive: Color(0xFF5ED39A),
      chartNegative: Color(0xFFFF7C96),
      chartNeutral: Color(0xFF91A0B8),
    );

    const assets = AppAssetTokens(
      lightSuffix: '_light',
      darkSuffix: '_dark',
      preferTintableIcons: true,
    );

    final colorScheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF90A0FF),
      onPrimary: Color(0xFF0D1728),
      secondary: Color(0xFF60D9F5),
      onSecondary: Color(0xFF0D1728),
      error: Color(0xFFFF7C96),
      onError: Color(0xFF0D1728),
      surface: Color(0xFF132033),
      onSurface: Color(0xFFEAF1FF),
      tertiary: Color(0xFFACA6FF),
      onTertiary: Color(0xFF0D1728),
    );

    final textTheme = _buildTextTheme(
      baseColor: colors.textPrimary,
      secondaryColor: colors.textSecondary,
      tertiaryColor: colors.textTertiary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.screenBackground,
      canvasColor: colors.surfacePrimary,
      shadowColor: colors.shadowColor,
      splashColor: colors.selectionBackground.withValues(alpha: 0.12),
      highlightColor: colors.selectionBackground.withValues(alpha: 0.08),
      dividerColor: colors.dividerPrimary,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.selectionBackground,
        selectionColor: colors.selectionBackground.withValues(alpha: 0.25),
        selectionHandleColor: colors.selectionBackground,
      ),
      dividerTheme: DividerThemeData(
        color: colors.dividerPrimary,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.snackSuccessBackground,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.dialogBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.bottomSheetBackground,
        modalBackgroundColor: colors.bottomSheetBackground,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderPrimary),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colors.surfaceSecondary,
        linearTrackColor: colors.surfaceSecondary,
      ),
      inputDecorationTheme: _buildInputDecorationTheme(colors, textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surfacePrimary,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: colors.iconPrimary),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.textBrand,
        unselectedLabelColor: colors.textSecondary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colors.textBrand, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.toggleActive;
          }
          return colors.toggleInactive;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: colors.borderPrimary),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.selectionBackground;
          }
          return colors.surfacePrimary;
        }),
        checkColor: WidgetStateProperty.all(colors.selectionForeground),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.selectionBackground;
          }
          return colors.borderPrimary;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceSecondary,
        selectedColor: colors.surfaceInteractive,
        disabledColor: colors.surfaceSecondary.withValues(alpha: 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.borderPrimary),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
        secondaryLabelStyle:
            textTheme.bodyMedium?.copyWith(color: colors.textBrand),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.surfaceInteractive,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? colors.textBrand : colors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.iconBrand : colors.iconSecondary,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surfacePrimary,
        selectedItemColor: colors.iconBrand,
        unselectedItemColor: colors.iconSecondary,
        selectedLabelStyle:
            textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.dialogBackground,
        surfaceTintColor: Colors.transparent,
        headerForegroundColor: colors.textInverse,
        headerBackgroundColor: colorScheme.primary,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.textInverse;
          }
          return colors.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(colorScheme.primary),
        todayBorder: BorderSide(color: colorScheme.primary),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colors.dialogBackground,
        hourMinuteTextColor: colors.textPrimary,
        dayPeriodTextColor: colors.textPrimary,
        dialHandColor: colorScheme.primary,
        dialTextColor: colors.textPrimary,
        entryModeIconColor: colors.iconPrimary,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        colors,
        charts,
        assets,
      ],
    );
  }

  static TextTheme _buildTextTheme({
    required Color baseColor,
    required Color secondaryColor,
    required Color tertiaryColor,
  }) {
    final base =
        Typography.material2021(platform: TargetPlatform.android).black.apply(
              bodyColor: baseColor,
              displayColor: baseColor,
              fontFamily: 'Gilroy',
            );
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: 'Golos'),
      displayMedium: base.displayMedium?.copyWith(fontFamily: 'Golos'),
      displaySmall: base.displaySmall?.copyWith(fontFamily: 'Golos'),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: 'Golos'),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'Golos'),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'Golos'),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: 'Golos',
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: baseColor,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: secondaryColor,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: baseColor),
      bodyMedium: base.bodyMedium?.copyWith(color: baseColor),
      bodySmall: base.bodySmall?.copyWith(color: secondaryColor),
      labelLarge: base.labelLarge?.copyWith(
        color: baseColor,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.labelMedium?.copyWith(color: secondaryColor),
      labelSmall: base.labelSmall?.copyWith(color: tertiaryColor),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(
    AppThemeColors colors,
    TextTheme textTheme,
  ) {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      filled: true,
      fillColor: colors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textTertiary),
      labelStyle: textTheme.titleSmall?.copyWith(color: colors.textSecondary),
      errorStyle: textTheme.bodySmall?.copyWith(
        color: colors.error,
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: border(colors.inputBorder),
      disabledBorder: border(colors.borderSecondary),
      focusedBorder: border(colors.inputFocusedBorder, width: 1.4),
      errorBorder: border(colors.inputErrorBorder, width: 1.4),
      focusedErrorBorder: border(colors.inputErrorBorder, width: 1.4),
      border: border(colors.inputBorder),
    );
  }
}
