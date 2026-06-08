import 'package:flutter/material.dart';

@immutable
class AppSpacingTokens {
  const AppSpacingTokens({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 20,
    this.xxl = 24,
    this.section = 32,
  });

  static const AppSpacingTokens value = AppSpacingTokens();

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double section;
}
