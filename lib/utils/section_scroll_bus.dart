import 'package:flutter/material.dart';

/// Двойное нажатие на уже открытую вкладку внизу.
/// Слушает только тот экран, который сейчас открыт.
class SectionScrollBus {
  SectionScrollBus._();

  static final SectionScrollBus instance = SectionScrollBus._();

  final ValueNotifier<int> tick = ValueNotifier<int>(0);

  void request() {
    tick.value++;
  }
}

/// Плавно поднимает список наверх, если он уже прикреплён к экрану.
Future<void> animateScrollToTop(ScrollController controller) async {
  if (!controller.hasClients) return;
  await controller.animateTo(
    0,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
  );
}
