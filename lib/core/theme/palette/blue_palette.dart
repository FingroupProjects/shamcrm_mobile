import 'package:crm_task_manager/core/theme/palette/app_palette.dart';
import 'package:flutter/material.dart';

class BluePalette {
  static const Color primary500 = Color(0xFF1D4ED8);
  static const Color primary700 = Color(0xFF102A5C);
  static const Color accent500 = Color(0xFF38BDF8);
  static const Color success500 = Color(0xFF16A34A);
  static const Color warning500 = Color(0xFFF59E0B);
  static const Color danger500 = Color(0xFFDC2626);
  static const Color info500 = Color(0xFF0EA5E9);

  static const AppPalette value = AppPalette(
    primary500: primary500,
    primary700: primary700,
    accent500: accent500,
    neutral0: Color(0xFFFFFFFF),
    neutral50: Color(0xFFF8FAFC),
    neutral100: Color(0xFFF1F5F9),
    neutral200: Color(0xFFE2E8F0),
    neutral300: Color(0xFFCBD5E1),
    neutral400: Color(0xFF94A3B8),
    neutral500: Color(0xFF64748B),
    neutral600: Color(0xFF475569),
    neutral700: Color(0xFF334155),
    neutral800: Color(0xFF1E293B),
    neutral900: Color(0xFF0F172A),
    success500: success500,
    warning500: warning500,
    danger500: danger500,
    info500: info500,
  );
}
