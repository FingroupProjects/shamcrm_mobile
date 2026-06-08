import 'package:crm_task_manager/core/theme/palette/app_palette.dart';
import 'package:flutter/material.dart';

class LightPalette {
  static const Color primary500 = Color(0xFF00B8D7);
  static const Color primary700 = Color(0xFF1E2E52);
  static const Color accent500 = Color(0xFF6A67F8);
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFFAFBFF);
  static const Color neutral100 = Color(0xFFF7FAFD);
  static const Color neutral200 = Color(0xFFF2F3F7);
  static const Color neutral300 = Color(0xFFE3E5ED);
  static const Color neutral400 = Color(0xFFCCD5E0);
  static const Color neutral500 = Color(0xFFB5BBC9);
  static const Color neutral600 = Color(0xFF99A4BA);
  static const Color neutral700 = Color(0xFF81899A);
  static const Color neutral800 = Color(0xFF6D7586);
  static const Color neutral900 = Color(0xFF23282D);
  static const Color success500 = Color(0xFF27AE60);
  static const Color warning500 = Color(0xFFFF9000);
  static const Color danger500 = Color(0xFFF2376F);
  static const Color info500 = Color(0xFF4759FF);

  // Compatibility aliases while migrating legacy code.
  static const Color brandPrimary = primary500;
  static const Color brandPrimaryDark = primary700;
  static const Color brandAccent = accent500;
  static const Color success = success500;
  static const Color warning = warning500;
  static const Color error = danger500;
  static const Color info = info500;

  static const AppPalette value = AppPalette(
    primary500: primary500,
    primary700: primary700,
    accent500: accent500,
    neutral0: neutral0,
    neutral50: neutral50,
    neutral100: neutral100,
    neutral200: neutral200,
    neutral300: neutral300,
    neutral400: neutral400,
    neutral500: neutral500,
    neutral600: neutral600,
    neutral700: neutral700,
    neutral800: neutral800,
    neutral900: neutral900,
    success500: success500,
    warning500: warning500,
    danger500: danger500,
    info500: info500,
  );
}
