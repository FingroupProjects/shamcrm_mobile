import 'dart:typed_data';

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
