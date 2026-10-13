import 'dart:typed_data';

import 'package:crm_task_manager/core/theme/app_theme.dart';
import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/widgets/pin_adaptive_contrast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(PinAdaptiveContrastCache.debugReset);

  test('bright wallpaper stays a light keypad', () {
    final sample = PinAdaptiveContrastController.sampleBackgroundLuminance(
      bytes: _solidImage(8, 255, 255, 255),
      imageWidth: 8,
      imageHeight: 8,
      screenSize: const Size(390, 844),
      fallbackLuminance: 0.55,
    );
    final palette = PinAdaptivePalette(
      headerLuminance: sample.header,
      keypadLuminance: sample.keypad,
      bottomLuminance: sample.bottom,
    );

    expect(sample.keypad, greaterThan(0.9));
    expect(palette.isDarkBackground(sample.keypad), isFalse);
  });

  test('dark wallpaper stays a dark keypad', () {
    final sample = PinAdaptiveContrastController.sampleBackgroundLuminance(
      bytes: _solidImage(8, 8, 10, 12),
      imageWidth: 8,
      imageHeight: 8,
      screenSize: const Size(390, 844),
      fallbackLuminance: 0.55,
    );
    final palette = PinAdaptivePalette(
      headerLuminance: sample.header,
      keypadLuminance: sample.keypad,
      bottomLuminance: sample.bottom,
    );

    expect(sample.keypad, lessThan(0.05));
    expect(palette.isDarkBackground(sample.keypad), isTrue);
  });

  test('cached palette is reused when the screen size barely changes', () {
    const palette = PinAdaptivePalette(
      headerLuminance: 0.82,
      keypadLuminance: 0.8,
      bottomLuminance: 0.79,
    );
    const cachedKey = 'custom|/a.jpg||18.0|100.0|0|false|390|844';
    const nearbyKey = 'custom|/a.jpg||18.0|100.0|0|false|391|846';

    PinAdaptiveContrastCache.save(cachedKey, palette);

    expect(PinAdaptiveContrastCache.lookup(nearbyKey)?.keypadLuminance, 0.8);
    expect(
      PinAdaptiveContrastCache.lookupSameWallpaper(
        'custom|/a.jpg||18.0|100.0|0|false|844|390',
      )?.keypadLuminance,
      0.8,
    );
    expect(
      PinAdaptiveContrastCache.lookup(
        'custom|/other.jpg||18.0|100.0|0|false|390|844',
      ),
      isNull,
    );
  });

  test('mid-animation gray is not treated as the finished light background', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();
    final halfwayBack = ThemeData.lerp(dark, light, 0.5);

    expect(
      PinAdaptiveContrastController.isSettledThemeBackground(
        current: halfwayBack.extension<AppThemeColors>()!.backgroundPrimary,
        target: light.extension<AppThemeColors>()!.backgroundPrimary,
      ),
      isFalse,
    );
    expect(
      PinAdaptiveContrastController.isSettledThemeBackground(
        current: light.extension<AppThemeColors>()!.backgroundPrimary,
        target: light.extension<AppThemeColors>()!.backgroundPrimary,
      ),
      isTrue,
    );
  });

  testWidgets(
    'light theme ink recovers after a fast dark-then-light switch',
    (tester) async {
      final contrast = PinAdaptiveContrastController();
      final themeController = AppThemeController.instance;
      final light = AppTheme.light(themeController.lightPalette);
      final dark = AppTheme.dark(themeController.darkPalette);
      // Яркость уже светлая, а цвет фона ещё на середине анимации.
      final halfwayBack = ThemeData.lerp(dark, light, 0.5);

      await _pumpContrast(tester, light, contrast);
      expect(_keypadOnDark(contrast), isFalse);

      await _pumpContrast(tester, halfwayBack, contrast);
      expect(_keypadOnDark(contrast), isTrue);
      final cachedWhileAnimating = PinAdaptiveContrastCache.savedKey;

      await _pumpContrast(tester, light, contrast);
      expect(_keypadOnDark(contrast), isFalse);
      expect(contrast.palette!.keypadLuminance, greaterThan(0.48));
      // Серый кадр анимации не должен затереть уже посчитанный светлый фон.
      if (cachedWhileAnimating != null) {
        final cached = PinAdaptiveContrastCache.lookup(cachedWhileAnimating);
        expect(cached, isNotNull);
        expect(cached!.isDarkBackground(cached.keypadLuminance), isFalse);
      }
    },
  );
}

bool _keypadOnDark(PinAdaptiveContrastController contrast) {
  final palette = contrast.palette;
  expect(palette, isNotNull);
  return palette!.isDarkBackground(palette.keypadLuminance);
}

Future<void> _pumpContrast(
  WidgetTester tester,
  ThemeData theme,
  PinAdaptiveContrastController contrast,
) {
  return tester.pumpWidget(
    Theme(
      data: theme,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: _ContrastHost(controller: contrast),
      ),
    ),
  );
}

class _ContrastHost extends StatefulWidget {
  final PinAdaptiveContrastController controller;

  const _ContrastHost({required this.controller});

  @override
  State<_ContrastHost> createState() => _ContrastHostState();
}

class _ContrastHostState extends State<_ContrastHost> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller.syncWithContext(context, onChanged: () {});
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

ByteData _solidImage(int size, int red, int green, int blue) {
  final data = ByteData(size * size * 4);
  for (var i = 0; i < size * size; i++) {
    data.setUint8(i * 4, red);
    data.setUint8(i * 4 + 1, green);
    data.setUint8(i * 4 + 2, blue);
    data.setUint8(i * 4 + 3, 255);
  }
  return data;
}
