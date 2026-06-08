import 'package:flutter/material.dart';

@immutable
class AppPalette {
  const AppPalette({
    required this.primary500,
    required this.primary700,
    required this.accent500,
    required this.neutral0,
    required this.neutral50,
    required this.neutral100,
    required this.neutral200,
    required this.neutral300,
    required this.neutral400,
    required this.neutral500,
    required this.neutral600,
    required this.neutral700,
    required this.neutral800,
    required this.neutral900,
    required this.success500,
    required this.warning500,
    required this.danger500,
    required this.info500,
  });

  final Color primary500;
  final Color primary700;
  final Color accent500;
  final Color neutral0;
  final Color neutral50;
  final Color neutral100;
  final Color neutral200;
  final Color neutral300;
  final Color neutral400;
  final Color neutral500;
  final Color neutral600;
  final Color neutral700;
  final Color neutral800;
  final Color neutral900;
  final Color success500;
  final Color warning500;
  final Color danger500;
  final Color info500;

  // Compatibility aliases while the project migrates from legacy names.
  Color get brandPrimary => primary500;
  Color get brandPrimaryDark => primary700;
  Color get brandAccent => accent500;
  Color get success => success500;
  Color get warning => warning500;
  Color get error => danger500;
  Color get info => info500;
}
