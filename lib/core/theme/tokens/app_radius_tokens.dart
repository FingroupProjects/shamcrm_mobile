import 'package:flutter/material.dart';

@immutable
class AppRadiusTokens {
  const AppRadiusTokens({
    this.xs = 8,
    this.sm = 12,
    this.md = 14,
    this.lg = 20,
    this.xl = 24,
    this.button = const BorderRadius.all(Radius.circular(14)),
    this.input = const BorderRadius.all(Radius.circular(14)),
    this.card = const BorderRadius.all(Radius.circular(20)),
    this.sheet = const BorderRadius.vertical(top: Radius.circular(24)),
  });

  static const AppRadiusTokens value = AppRadiusTokens();

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final BorderRadius button;
  final BorderRadius input;
  final BorderRadius card;
  final BorderRadius sheet;
}
